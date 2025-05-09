"""
device Data Management and MQTT Integration.

This module handles the registration and data processing for IoT devices using MQTT messages.
It supports registering devices, processing sensor data, water usage data, and handling predictions.

### Key Features:
1. **device Registration**:
   - Registers a new IoT device by storing its details in MongoDB.
   - Subscribes the device to its relevant MQTT topics.

2. **Sensor Data Management**:
   - Records sensor data received from MQTT and updates the MongoDB document for the device.
   - Emits updates via Socket.IO for real-time communication with connected clients.

3. **Water Usage Management**:
   - Records water usage statistics and updates MongoDB for the respective device.

4. **Prediction Processing**:
   - Processes prediction-related data (currently a placeholder).

### Dependencies:
- `bson`: For working with MongoDB ObjectId.
- `redis`: For caching and tracking active devices.
- `pymongo`: For MongoDB operations.
- `json`: For parsing and formatting JSON payloads.
- `socketio`: For real-time event communication.

### Error Handling:
- Logs detailed errors for issues like invalid JSON, missing keys, and database operations.

MongoDB Collection:
- devices are stored in the `device_COLLECTION`.

"""

import json
from datetime import datetime

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

    Args:
        topic (str): The MQTT topic string (e.g., "device_id/record/sensor_data").

    Returns:
        str: Extracted device ID.
    """
    return topic.split('/')[0]


def register_device(payload: str) -> None:
    """
    Registers a new IoT device.

    Args:
        payload (str): JSON string containing the device ID.

    Returns:
        None

    Steps:
        1. Parses the JSON payload to extract the device ID.
        2. Attempts to insert a new device record into MongoDB.
        3. Handles duplicate registration by skipping insertion.
        4. Subscribe the device to its relevant MQTT topics.

    Exceptions:
        - Handles `KeyError` for missing keys in payload.
        - Handles `JSONDecodeError` for invalid JSON payloads.
        - Logs unexpected errors.

    Example JSON Payload:
    {
        "device_id": "63c9f5e56e13d1d1234abcd9"
    }
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

    Args:
        payload (str): JSON string containing prediction data.
        topic (str): MQTT topic string.

    Returns:
        None
    """
    json_data = json.loads(payload)
    sensor_data = json_data.get('sensor_data')
    moisture = sensor_data['moisture']
    temperature = sensor_data['temperature']
    humidity = sensor_data['humidity']
    if not all([moisture, temperature, humidity]):
        print('Invalid sensor data:', sensor_data)
        return
    df = pd.DataFrame({
        'Soil Moisture': [moisture],
        'Temperature': [temperature],
        'Air Humidity': [humidity]
    })
    device_id = extract_device_id(topic)
    print('JSON data:', json_data)
    print('DataFrame:', df)
    print('device ID:', device_id)
    prediction = predict_water(df)
    print('Prediction:', prediction)
    verdict = 1 if prediction[0] == 1 else 0
    print('Verdict:', verdict)
    mqtt.publish(f'{device_id}/prediction',
                 json.dumps({'prediction': verdict, 'timestamp': datetime.now().isoformat()}))


def record_sensor_data(payload: str, topic: str) -> None:
    """
    records sensor data from MQTT messages.

    Args:
        payload (str): JSON string containing sensor data and timestamp.
        topic (str): MQTT topic string.

    Returns:
        None

    workflow:
        1. parses the JSON payload to extract sensor data and timestamp.
        2. updates the device's `record` field in MongoDB.
        3. emits real-time updates via Socket.IO to connected users.
        4. handles Redis operations for tracking active users.

    exceptions:
        - Handles invalid JSON payloads, invalid device IDs, and database errors.

    example JSON Payload:
    {
        "sensor_data": {
            "temperature": 25,
            "humidity": 60,
            "moisture": 40
        },
        "timestamp": "2025-01-28T12:34:56"
    }
    """
    try:
        json_data = json.loads(payload)
        if 'sensor_data' not in json_data or 'timestamp' not in json_data:
            print('Invalid payload: Missing sensor_data or timestamp:', json_data)
            return

        device_id = extract_device_id(topic)
        res = mongo_db[DEVICE_COLLECTION].find_one({'_id': ObjectId(device_id)})

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
                user_data = r.get(user_key) if r.exists(user_key) else ""
                print("\n\n SOCKET ID:", user_data, "\n\n")
                socketio.emit('record', json_data, room=user_data)
        except ResponseError as redis_error:
            print(f"Redis ResponseError: {redis_error}")
        finally:
            print(f"Redis value for {device_id}: {r.get(device_id)}")

    except Exception as e:
        print(f"Unexpected error: {e}")


def record_water_used(payload: str, topic: str) -> None:
    """
    records water usage data from MQTT messages.

    Args:
        payload (str): JSON string containing water usage data and timestamp.
        topic (str): MQTT topic string.

    Returns:
        None

    workflow:
        1. parses the JSON payload to extract water usage and timestamp.
        2. updates the device's `water_usage` field in MongoDB.

    exceptions:
        - Handles invalid JSON payloads, invalid device IDs, and database errors.

    example JSON Payload:
    {
        "water_used": 50,
        "date": "2025-01"
    }
    """
    try:
        json_data = json.loads(payload)
        if 'water_used' not in json_data or 'date' not in json_data:
            print('Invalid payload: Missing water_used or date:', json_data)
            return

        device_id = extract_device_id(topic)
        res = mongo_db[DEVICE_COLLECTION].find_one({'_id': ObjectId(device_id)})

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

    except Exception as e:
        print(f"Unexpected error: {e}")
