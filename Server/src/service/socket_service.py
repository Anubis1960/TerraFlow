"""
Service handlers for IoT irrigation devices, including user management, device interaction,
and irrigation scheduling.

### Functions:
1. **handle_connect** - Handles the event when a client connects.
2. **handle_disconnect** - Handles the event when a client disconnects.
3. **handle_irrigate** - Triggers an irrigation event for a specific device.
4. **handle_add_device** - Adds a device to a user's account and updates Redis.
5. **handle_remove_device** - Removes a device from a user's account and updates Redis.
6. **handle_schedule_irrigation** - Schedules irrigation for a specific device.
7. **handle_register** - Registers a new user.
8. **handle_login** - Logs in an existing user.
9. **handle_retrieve_device_data** - Retrieves device data from the database and sends it to the client.
10. **remap_redis** - Updates Redis with new user-device associations.
"""

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

    Args:
        data (dict): Data associated with the connection.

    Returns:
        None
    """
    print(data)


def handle_disconnect(data) -> None:
    """
    Handles the event when a client disconnects.

    Args:
        data (dict): Data associated with the disconnection.

    Returns:
        None
    """
    print(data)


def handle_irrigate(device_id: str) -> None:
    """
    Triggers an irrigation event for a specific device.

    Args:
        device_id (str): The unique identifier of the device to trigger irrigation for.

    Returns:
        None
    """
    json_data = {
        'irrigate': True
    }
    mqtt.publish(f'{device_id}/irrigate', json.dumps(json_data))


def handle_schedule_irrigation(device_id: str, schedule: dict) -> None:
    """
    schedules irrigation for a specific device.

    Args:
        device_id (str): The unique identifier of the device.
        schedule (dict): The schedule for irrigation containing the type and time.

    Returns:
        None
    """
    mqtt.publish(f'{device_id}/schedule', json.dumps(schedule))


def remap_redis(device_id: str, user_id: str, socket_id: str) -> None:
    """
    Updates Redis with new user-device associations.

    Args:
        device_id (str): The unique identifier of the device.
        user_id (str): The unique identifier of the user.
        socket_id (str): The socket ID for the current connection.

    Returns:
        None
    """
    try:
        device_key = f"device:{device_id}"
        if r.exists(device_key):
            user_list = json.loads(r.get(device_key))
            if user_id not in user_list:
                user_list.append(user_id)
            json_data = json.dumps(user_list)
            if json_data != '[]':
                r.set(device_id, json_data)
            else:
                r.delete(device_id)

            user_key = f"user:{user_id}"
            print('user_key:', user_key)
            print('socket_id:', socket_id)
            r.set(user_key, socket_id)
        else:
            print('device not found')
    except Exception as e:
        print(f"Unexpected error: {e}")


def handle_export(device_id: str, socket_id: str) -> None:
    """
    exports data from the device to a file.

    Args:
        device_id (str): The unique identifier of the device.
        socket_id (str): the sid of the socket connection.

    Returns:
        None
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
