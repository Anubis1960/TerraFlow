import json
from redis import ResponseError
from src.util.db import r, mongo_db, CONTROLLER_COLLECTION
from src.util.extensions import socketio, mqtt
from pymongo.errors import DuplicateKeyError


def extract_device_id(topic: str) -> str:
    return topic.split('/')[0]


def register_device(payload: str) -> None:
    try:
        json_data = json.loads(payload)
        print('JSON data:', json_data)
        
        device_id = json_data['device_id']

        ctrl_json = {
            '_id': device_id,
            'record': [],
            'water_used_month': []
        }

        try:
            # Attempt to insert the new device
            controller = mongo_db[CONTROLLER_COLLECTION].insert_one(ctrl_json)
            print('Controller registered:', controller.inserted_id)
        except DuplicateKeyError:
            print(f"Device with ID {device_id} is already registered. Skipping insertion.")

        # Subscribe to device topics
        
        mqtt.subscribe(f'{device_id}/record')
        mqtt.subscribe(f'{device_id}/predict')

    except KeyError as e:
        print(f"KeyError: Missing key in payload - {e}")
    except json.JSONDecodeError as e:
        print(f"JSONDecodeError: Invalid JSON payload - {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")


def predict(payload: str, topic: str) -> None:
    json_data = json.loads(payload)
    device_id = extract_device_id(topic)
    print('JSON data:', json_data)
    print('Device ID:', device_id)


def record_sensor_data(payload: str, topic: str) -> None:
    try:
        # Parse the incoming payload
        json_data = json.loads(payload)
        if 'sensor_data' not in json_data or 'timestamp' not in json_data:
            print('Invalid payload: Missing sensor_data or timestamp:', json_data)
            return

        device_id = extract_device_id(topic)

        # Retrieve the device record from MongoDB
        res = mongo_db[CONTROLLER_COLLECTION].find_one({'_id': device_id})
        if not res:
            print(f"Device with ID {device_id} not found in database.")
            return

        # Safely get or initialize the 'record' field
        sensor_data = res.get('record', [])
        if not isinstance(sensor_data, list):
            print(f"Invalid data type for 'record'. Expected list, found {type(sensor_data)}.")
            return

        # Append new sensor data
        sensor_data.append(json_data)
        mongo_db[CONTROLLER_COLLECTION].update_one({'_id': device_id}, {'$set': {'record': sensor_data}})

        print(f"Updated record for device {device_id}")
        # Redis and socket emission
        try:
            user_list = []
            if r.exists(device_id):
                user_list = json.loads(r.get(device_id))
            else:
                print(f"No active Redis key for device {device_id}.")

            for user in user_list:
                socketio.emit('record', json_data, room=user['socket_id'])

        except ResponseError as redis_error:
            print(f"Redis ResponseError: {redis_error}")
        except Exception as redis_exception:
            print(f"Unexpected Redis error: {redis_exception}")
        finally:
            # Debug Redis state
            redis_value = r.get(device_id)
            print(f"Final Redis value for {device_id}: {redis_value}")

    except json.JSONDecodeError as decode_error:
        print(f"JSON decoding error: {decode_error}")
    except Exception as general_error:
        print(f"Unexpected error in record function: {general_error}")


def record_water_used(payload: str, topic: str) -> None:
    try:
        # Parse the incoming payload
        json_data = json.loads(payload)
        if 'water_used' not in json_data or 'timestamp' not in json_data:
            print('Invalid payload: Missing water_used or timestamp:', json_data)
            return

        device_id = extract_device_id(topic)

        # Retrieve the device record from MongoDB
        res = mongo_db[CONTROLLER_COLLECTION].find_one({'_id': device_id})
        if not res:
            print(f"Device with ID {device_id} not found in database.")
            return

        # Safely get or initialize the 'water_used_month' field
        water_used = res.get('water_used_month', [])
        if not isinstance(water_used, list):
            print(f"Invalid data type for 'water_used_month'. Expected list, found {type(water_used)}.")
            return

        # Append new water used data
        water_used.append(json_data)
        mongo_db[CONTROLLER_COLLECTION].update_one({'_id': device_id}, {'$set': {'water_used_month': water_used}})

        print(f"Updated water used data for device {device_id}")

    except json.JSONDecodeError as decode_error:
        print(f"JSON decoding error: {decode_error}")
    except Exception as general_error:
        print(f"Unexpected error in record function: {general_error}")

