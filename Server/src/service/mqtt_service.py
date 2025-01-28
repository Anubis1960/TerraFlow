"""
Controller Data Management and MQTT Integration.

This module handles the registration and data processing for IoT controllers using MQTT messages.
It supports registering controllers, processing sensor data, water usage data, and handling predictions.

### Key Features:
1. **Controller Registration**:
   - Registers a new IoT controller by storing its details in MongoDB.
   - Subscribes the controller to its relevant MQTT topics.

2. **Sensor Data Management**:
   - Records sensor data received from MQTT and updates the MongoDB document for the controller.
   - Emits updates via Socket.IO for real-time communication with connected clients.

3. **Water Usage Management**:
   - Records water usage statistics and updates MongoDB for the respective controller.

4. **Prediction Processing**:
   - Processes prediction-related data (currently a placeholder).

### Dependencies:
- `bson`: For working with MongoDB ObjectId.
- `redis`: For caching and tracking active controllers.
- `pymongo`: For MongoDB operations.
- `json`: For parsing and formatting JSON payloads.
- `socketio`: For real-time event communication.

### Error Handling:
- Logs detailed errors for issues like invalid JSON, missing keys, and database operations.

MongoDB Collection:
- Controllers are stored in the `CONTROLLER_COLLECTION`.

"""

import json
from bson.errors import InvalidId
from redis import ResponseError
from src.util.db import r, mongo_db, CONTROLLER_COLLECTION
from src.util.extensions import socketio, mqtt
from pymongo.errors import DuplicateKeyError
from bson.objectid import ObjectId


def extract_controller_id(topic: str) -> str:
    """
    Extracts the controller ID from an MQTT topic string.

    Args:
        topic (str): The MQTT topic string (e.g., "controller_id/record/sensor_data").

    Returns:
        str: Extracted controller ID.
    """
    return topic.split('/')[0]


def register_controller(payload: str) -> None:
    """
    Registers a new IoT controller.

    Args:
        payload (str): JSON string containing the controller ID.

    Steps:
        1. Parses the JSON payload to extract the controller ID.
        2. Attempts to insert a new controller record into MongoDB.
        3. Handles duplicate registration by skipping insertion.
        4. Subscribes the controller to its relevant MQTT topics.

    Exceptions:
        - Handles `KeyError` for missing keys in payload.
        - Handles `JSONDecodeError` for invalid JSON payloads.
        - Logs unexpected errors.

    Example JSON Payload:
    {
        "controller_id": "63c9f5e56e13d1d1234abcd9"
    }
    """
    try:
        json_data = json.loads(payload)
        print('JSON data:', json_data)

        controller_id = json_data['controller_id']

        ctrl_json = {
            '_id': ObjectId(controller_id),
            'record': [],
            'water_used_month': []
        }

        try:
            controller = mongo_db[CONTROLLER_COLLECTION].insert_one(ctrl_json)
            print('Controller registered:', controller.inserted_id)
        except DuplicateKeyError:
            print(f"Controller with ID {controller_id} is already registered. Skipping insertion.")

        # Manage MQTT subscriptions
        mqtt.unsubscribe(f'{controller_id}/record/sensor_data')
        mqtt.unsubscribe(f'{controller_id}/record/water_used')
        mqtt.unsubscribe(f'{controller_id}/predict')

        mqtt.subscribe(f'{controller_id}/record/sensor_data')
        mqtt.subscribe(f'{controller_id}/record/water_used')
        mqtt.subscribe(f'{controller_id}/predict')

    except KeyError as e:
        print(f"KeyError: Missing key in payload - {e}")
    except json.JSONDecodeError as e:
        print(f"JSONDecodeError: Invalid JSON payload - {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")


def predict(payload: str, topic: str) -> None:
    """
    Handles prediction requests for a controller.

    Args:
        payload (str): JSON string containing prediction data.
        topic (str): MQTT topic string.

    Logs the prediction data and controller ID for further processing.

    Note:
        - This function currently serves as a placeholder for actual prediction logic.
    """
    json_data = json.loads(payload)
    controller_id = extract_controller_id(topic)
    print('JSON data:', json_data)
    print('Controller ID:', controller_id)


def record_sensor_data(payload: str, topic: str) -> None:
    """
    Records sensor data from MQTT messages.

    Args:
        payload (str): JSON string containing sensor data and timestamp.
        topic (str): MQTT topic string.

    Workflow:
        1. Parses the JSON payload to extract sensor data and timestamp.
        2. Updates the controller's `record` field in MongoDB.
        3. Emits real-time updates via Socket.IO to connected users.
        4. Handles Redis operations for tracking active users.

    Exceptions:
        - Handles invalid JSON payloads, invalid controller IDs, and database errors.

    Example JSON Payload:
    {
        "sensor_data": {
            "temperature": 25,
            "humidity": 60,
            "soil_moisture": 40
        },
        "timestamp": "2025-01-28T12:34:56"
    }
    """
    try:
        json_data = json.loads(payload)
        if 'sensor_data' not in json_data or 'timestamp' not in json_data:
            print('Invalid payload: Missing sensor_data or timestamp:', json_data)
            return

        controller_id = extract_controller_id(topic)
        res = mongo_db[CONTROLLER_COLLECTION].find_one({'_id': ObjectId(controller_id)})

        if not res:
            print(f"Controller with ID {controller_id} not found in database.")
            return

        sensor_data = res.get('record', [])
        if not isinstance(sensor_data, list):
            print(f"Invalid data type for 'record'. Expected list, found {type(sensor_data)}.")
            return

        sensor_data.append(json_data)
        mongo_db[CONTROLLER_COLLECTION].update_one({'_id': ObjectId(controller_id)}, {'$set': {'record': sensor_data}})

        # Emit real-time updates
        try:
            user_list = json.loads(r.get(controller_id)) if r.exists(controller_id) else []
            for user in user_list:
                socketio.emit('record', json_data, room=user['socket_id'])
        except ResponseError as redis_error:
            print(f"Redis ResponseError: {redis_error}")
        finally:
            print(f"Redis value for {controller_id}: {r.get(controller_id)}")

    except Exception as e:
        print(f"Unexpected error: {e}")


def record_water_used(payload: str, topic: str) -> None:
    """
    Records water usage data from MQTT messages.

    Args:
        payload (str): JSON string containing water usage data and timestamp.
        topic (str): MQTT topic string.

    Workflow:
        1. Parses the JSON payload to extract water usage and timestamp.
        2. Updates the controller's `water_used_month` field in MongoDB.

    Exceptions:
        - Handles invalid JSON payloads, invalid controller IDs, and database errors.

    Example JSON Payload:
    {
        "water_used": 50,
        "timestamp": "2025-01"
    }
    """
    try:
        json_data = json.loads(payload)
        if 'water_used' not in json_data or 'timestamp' not in json_data:
            print('Invalid payload: Missing water_used or timestamp:', json_data)
            return

        controller_id = extract_controller_id(topic)
        res = mongo_db[CONTROLLER_COLLECTION].find_one({'_id': ObjectId(controller_id)})

        if not res:
            print(f"Controller with ID {controller_id} not found in database.")
            return

        water_used = res.get('water_used_month', [])
        if not isinstance(water_used, list):
            print(f"Invalid data type for 'water_used_month'. Expected list, found {type(water_used)}.")
            return

        water_used.append(json_data)
        mongo_db[CONTROLLER_COLLECTION].update_one({'_id': ObjectId(controller_id)},
                                                   {'$set': {'water_used_month': water_used}})
        print(f"Updated water used data for controller {controller_id}")

    except Exception as e:
        print(f"Unexpected error: {e}")
