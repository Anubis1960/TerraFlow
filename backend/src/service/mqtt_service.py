import json
import pandas as pd
from bson.objectid import ObjectId
from pymongo.errors import DuplicateKeyError
from redis import ResponseError
from src.config.mongo import mongo_db, DEVICE_COLLECTION
from src.config.redis import r
from src.config.protocol import mqtt, socketio
from src.utils.predict import predict_water


def extract_device_id(topic: str) -> str:
    """
    Extracts the device ID from an MQTT topic string.

    :param topic: str: The MQTT topic string (e.g., "device_id/record/sensor_data").
    :return: str: Extracted device ID.
    """
    return topic.split('/')[0]


def register_device(payload: str) -> None:
    """
    Registers a new IoT device.

    :param payload: str: JSON string containing the device ID.
    :return: None
    """
    try:
        json_data = json.loads(payload)
        print('JSON data:', json_data)

        device_id = json_data['device_id']

        device = mongo_db[DEVICE_COLLECTION].find_one({'_id': ObjectId(device_id)})
        if not device:
            print(f"device with ID {device_id} already exists. Skipping registration.")

            ctrl_json = {
                '_id': ObjectId(device_id),
                'name': device_id,
                'record': [],
                'water_usage': []
            }

            try:
                device = mongo_db[DEVICE_COLLECTION].insert_one(ctrl_json)
                print('device registered:', device.inserted_id)
            except DuplicateKeyError:
                print(f"device with ID {device_id} is already registered. Skipping insertion.")

        # Manage MQTT subscriptions
        mqtt.unsubscribe(f'{device_id}/record/sensor_data')
        mqtt.unsubscribe(f'{device_id}/record/water_used')
        mqtt.unsubscribe(f'{device_id}/predict')

        mqtt.subscribe(f'{device_id}/record/sensor_data')
        mqtt.subscribe(f'{device_id}/record/water_used')
        mqtt.subscribe(f'{device_id}/predict')

    except KeyError as e:
        print(f"KeyError: Missing key in payload - {e}")
    except json.JSONDecodeError as e:
        print(f"JSONDecodeError: Invalid JSON payload - {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")


def predict(payload: str, topic: str) -> None:
    """
    handles prediction requests for a device.

    :param payload: str: JSON string containing sensor data.
    :param topic: str: MQTT topic string.
    :return: None
    """
    json_data = json.loads(payload)
    sensor_data = json_data.get('sensor_data')
    moisture = sensor_data['moisture']
    temperature = sensor_data['temperature']
    humidity = sensor_data['humidity']
    if not (isinstance(moisture, (int, float)) and
            isinstance(temperature, (int, float)) and
            isinstance(humidity, (int, float))):
        print('Invalid sensor data:', sensor_data)
        return
    df = pd.DataFrame({
        'Soil Moisture': [moisture],
        'Temperature': [temperature],
        'Air Humidity': [humidity]
    })
    device_id = extract_device_id(topic)
    prediction = predict_water(df)
    verdict = 1 if prediction[0] == 1 else 0
    print('Verdict:', verdict)
    mqtt.publish(f'{device_id}/prediction',
                 json.dumps({'prediction': verdict}))


def record_sensor_data(payload: str, topic: str) -> None:
    """
    records sensor data from MQTT messages.

    :param payload: str: JSON string containing sensor data and timestamp.
    :param topic: str: MQTT topic string.
    :return: None
    """
    try:
        json_data = json.loads(payload)
        if 'sensor_data' not in json_data or 'timestamp' not in json_data:
            print('Invalid payload: Missing sensor_data or timestamp:', json_data)
            return

        device_id = extract_device_id(topic)
        res = mongo_db[DEVICE_COLLECTION].find_one({'_id': ObjectId(device_id)})
        json_data['device_id'] = device_id

        if not res:
            print(f"device with ID {device_id} not found in database.")
            return

        sensor_data = res.get('record', [])
        if not isinstance(sensor_data, list):
            print(f"Invalid data type for 'record'. Expected list, found {type(sensor_data)}.")
            return

        sensor_data.append(json_data)
        mongo_db[DEVICE_COLLECTION].update_one({'_id': ObjectId(device_id)}, {'$set': {'record': sensor_data}})

        try:
            device_key = f"device:{device_id}"
            user_list = json.loads(r.get(device_key)) if r.exists(device_key) else []

            for user in user_list:
                user_key = f"user:{user}"
                socket_id = r.get(user_key) if r.exists(user_key) else None

                if not socket_id:
                    print(f"No socket_id found for user {user}. Skipping emit.")
                    if r.exists(device_key):
                        _user_list = json.loads(r.get(device_key))
                        if user in _user_list:
                            _user_list.remove(user)
                            r.set(device_key, json.dumps(_user_list))
                            print(f"Removed user {user} from device {device_id}.")
                    continue

                socketio.emit(f"{device_id}/record", json_data, room=socket_id)

        except ResponseError as redis_error:
            print(f"Redis ResponseError: {redis_error}")

    except Exception as e:
        print(f"Unexpected error: {e}")


def record_water_used(payload: str, topic: str) -> None:
    """
    records water usage data from MQTT messages.

    :param payload: str: JSON string containing water usage data and timestamp.
    :param topic: str: MQTT topic string.
    :return: None
    """
    try:
        json_data = json.loads(payload)
        if 'water_used' not in json_data or 'date' not in json_data:
            print('Invalid payload: Missing water_used or date:', json_data)
            return

        device_id = extract_device_id(topic)
        res = mongo_db[DEVICE_COLLECTION].find_one({'_id': ObjectId(device_id)})
        json_data['device_id'] = device_id

        if not res:
            print(f"device with ID {device_id} not found in database.")
            return

        water_used = res.get('water_usage', [])
        if not isinstance(water_used, list):
            print(f"Invalid data type for 'water_usage'. Expected list, found {type(water_used)}.")
            return

        last_entry = water_used[-1] if water_used else None

        if last_entry and last_entry['date'] == json_data['date']:
            last_entry['water_used'] += json_data['water_used']
            water_used[-1] = last_entry
        else:
            water_used.append(json_data)

        mongo_db[DEVICE_COLLECTION].update_one({'_id': ObjectId(device_id)},
                                               {'$set': {'water_usage': water_used}})

        try:
            device_key = f"device:{device_id}"
            user_list = json.loads(r.get(device_key)) if r.exists(device_key) else []
            for user in user_list:
                user_key = f"user:{user}"
                user_data = r.get(user_key) if r.exists(user_key) else ""
                socketio.emit(f"{device_id}/water_usage", json_data, room=user_data)
                print(f"Emitted data to user {user} with socket ID {user_data}")
        except ResponseError as redis_error:
            print(f"Redis ResponseError: {redis_error}")

    except Exception as e:
        print(f"Unexpected error: {e}")
