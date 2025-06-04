import json
import bson.errors
import regex as re
from bson.objectid import ObjectId
from src.config.mongo import mongo_db, DEVICE_COLLECTION
from src.config.protocol import mqtt, socketio
from src.config.redis import r
from src.utils.excel_manager import export_to_excel

email_regex = re.compile(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$')


def handle_connect(data) -> None:
    """
    Handles the event when a client connects.

    :param data: Data associated with the connection.
    :return: None
    """
    print(data)


def handle_disconnect(data) -> None:
    """
    Handles the event when a client disconnects.

    :param data: Data associated with the disconnection.
    :return: None
    """
    print(data)


def handle_irrigate(device_id: str) -> None:
    """
    Triggers an irrigation event for a specific device.

    :param device_id: str: The unique identifier of the device to trigger irrigation for.
    :return: None
    """
    json_data = {
        'irrigate': True
    }
    mqtt.publish(f'{device_id}/irrigate', json.dumps(json_data))


def handle_schedule_irrigation(device_id: str, schedule: dict) -> None:
    """
    schedules irrigation for a specific device.

    :param device_id: str: The unique identifier of the device.
    :param schedule: dict: The schedule for irrigation contains the type and time.
    :return: None
    """
    mqtt.publish(f'{device_id}/schedule', json.dumps(schedule))


def handle_irrigation_type(device_id: str, irrigation_type: str, schedule: dict) -> None:
    """
    schedules irrigation for a specific device.

    :param device_id: str: The unique identifier of the device.
    :param irrigation_type: str: The type of irrigation to be scheduled.
    :param schedule: dict: The schedule for irrigation contains the time.
    :return: None
    """
    json_data = {
        'irrigation_type': irrigation_type,
        'schedule': schedule
    }
    mqtt.publish(f'{device_id}/irrigation_type', json.dumps(json_data))


def remap_redis(device_id: str, user_id: str, socket_id: str) -> None:
    """
    Updates Redis with new user-device associations.

    :param device_id: str: The unique identifier of the device.
    :param user_id: str: The unique identifier of the user.
    :param socket_id: str: The socket ID for the current connection.
    :return: None
    """
    try:
        device_key = f"device:{device_id}"
        raw_data = r.get(device_key)

        if raw_data is None:
            print('device key not found')
            return

        user_list = json.loads(raw_data)
        if user_id not in user_list:
            user_list.append(user_id)

        json_data = json.dumps(user_list)
        if json_data != '[]':
            r.set(device_key, json_data)
        else:
            r.delete(device_key)

        user_key = f"user:{user_id}"
        r.set(user_key, socket_id)

        print(f"Redis value for {device_key}: {r.get(device_key)}")
        print(f"Redis value for {user_key}: {r.get(user_key)}")

    except Exception as e:
        print(f"Unexpected error: {e}")


def handle_export(device_id: str, socket_id: str) -> None:
    """
    exports data from the device to a file.

    :param device_id: str: str: the unique identifier of the device.
    :param socket_id: str: the sid of the socket connection.
    :return: None
    """
    try:
        res = mongo_db[DEVICE_COLLECTION].find_one({'_id': ObjectId(device_id)})
        print('res:', res)
        if not res:
            print(f"device with ID {device_id} not found.")
            return

        buf = export_to_excel(res)

        socketio.emit('export_response', {'file': buf.getvalue()}, room=socket_id)

    except bson.errors.InvalidId as e:
        print(f"Invalid device ID: {device_id}, error: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")
