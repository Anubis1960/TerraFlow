import json
from bson.errors import InvalidId
from redis import ResponseError
from src.util.db import r, mongo_db, CONTROLLER_COLLECTION
from src.util.extensions import socketio, mqtt
from pymongo.errors import DuplicateKeyError
from bson.objectid import ObjectId


def extract_controller_id(topic: str) -> str:
    return topic.split('/')[0]


def register_controller(payload: str) -> None:
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
            # Attempt to insert the new controller
            controller = mongo_db[CONTROLLER_COLLECTION].insert_one(ctrl_json)
            print('Controller registered:', controller.inserted_id)
        except DuplicateKeyError:
            print(f"controller with ID {controller_id} is already registered. Skipping insertion.")

        # Subscribe to controller topics

        print(f"Subscribing to topics for controller {controller_id}, topics: {controller_id}/record,"
              f" {controller_id}/predict")

        mqtt.subscribe(f'{controller_id}/record/sensor_data')
        mqtt.subscribe(f'{controller_id}/record/water_used')
        mqtt.subscribe(f'{controller_id}/predict')

    except KeyError as e:
        print(f"KeyError: Missing key in payload - {e}")
    except json.JSONDecodeError as e:
        print(f"JSONDecodeError: Invalid JSON payload - {e}")
    except ValueError as e:
        print(f"ValueError: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")


def predict(payload: str, topic: str) -> None:
    json_data = json.loads(payload)
    controller_id = extract_controller_id(topic)
    print('JSON data:', json_data)
    print('controller ID:', controller_id)


def record_sensor_data(payload: str, topic: str) -> None:
    try:
        # Parse the incoming payload
        json_data = json.loads(payload)
        if 'sensor_data' not in json_data or 'timestamp' not in json_data:
            print('Invalid payload: Missing sensor_data or timestamp:', json_data)
            return

        controller_id = extract_controller_id(topic)

        # Retrieve the controller record from MongoDB
        res = mongo_db[CONTROLLER_COLLECTION].find_one({'_id': ObjectId(controller_id)})
        if not res:
            print(f"controller with ID {controller_id} not found in database.")
            return

        # Safely get or initialize the 'record' field
        sensor_data = res.get('record', [])
        if not isinstance(sensor_data, list):
            print(f"Invalid data type for 'record'. Expected list, found {type(sensor_data)}.")
            return

        # Append new sensor data
        sensor_data.append(json_data)
        mongo_db[CONTROLLER_COLLECTION].update_one({'_id': ObjectId(controller_id)}, {'$set': {'record': sensor_data}})
        # Redis and socket emission
        try:
            user_list = []
            if r.exists(controller_id):
                user_list = json.loads(r.get(controller_id))
            else:
                print(f"No active Redis key for controller {controller_id}.")

            for user in user_list:
                socketio.emit('record', json_data, room=user['socket_id'])

        except ResponseError as redis_error:
            print(f"Redis ResponseError: {redis_error}")
        except ValueError as e:
            print(f"ValueError: {e}")
        except Exception as redis_exception:
            print(f"Unexpected Redis error: {redis_exception}")
        finally:
            # Debug Redis state
            redis_value = r.get(controller_id)
            print(f"Final Redis value for {controller_id}: {redis_value}")

    except json.JSONDecodeError as decode_error:
        print(f"JSON decoding error: {decode_error}")
    except InvalidId as e:
        print(f"InvalidId: {e}")
    except Exception as general_error:
        print(f"Unexpected error in record function: {general_error}")


def record_water_used(payload: str, topic: str) -> None:
    try:
        # Parse the incoming payload
        json_data = json.loads(payload)
        if 'water_used' not in json_data or 'timestamp' not in json_data:
            print('Invalid payload: Missing water_used or timestamp:', json_data)
            return

        controller_id = extract_controller_id(topic)

        # Retrieve the controller record from MongoDB
        res = mongo_db[CONTROLLER_COLLECTION].find_one({'_id': ObjectId(controller_id)})
        if not res:
            print(f"controller with ID {controller_id} not found in database.")
            return

        # Safely get or initialize the 'water_used_month' field
        water_used = res.get('water_used_month', [])
        if not isinstance(water_used, list):
            print(f"Invalid data type for 'water_used_month'. Expected list, found {type(water_used)}.")
            return

        # Append new water used data
        water_used.append(json_data)
        mongo_db[CONTROLLER_COLLECTION].update_one({'_id': ObjectId(controller_id)},
                                                   {'$set': {'water_used_month': water_used}})

        print(f"Updated water used data for controller {controller_id}")

    except json.JSONDecodeError as decode_error:
        print(f"JSON decoding error: {decode_error}")
    except ValueError as e:
        print(f"ValueError: {e}")
    except Exception as general_error:
        print(f"Unexpected error in record function: {general_error}")
