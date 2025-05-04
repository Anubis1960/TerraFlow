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
from redis.exceptions import ResponseError
from src.config.mongo import mongo_db, DEVICE_COLLECTION, USER_COLLECTION
from src.config.redis import r
from src.config.protocol import mqtt, socketio
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


# TODO: Convert to REST
def handle_add_device(device_id: str, user_id: str, socket_id: str) -> None:
    """
    Adds a device to a user's account and updates Redis.

    Args:
        device_id (str): The unique identifier of the device to add.
        user_id (str): The unique identifier of the user.
        socket_id (str): The socket ID for the current connection.

    Returns:
        None
    """
    try:
        u_res = mongo_db[USER_COLLECTION].find_one({'_id': ObjectId(user_id)})

        if not u_res:
            print(f"User with ID {user_id} not found.")
            return
        
        devices = u_res.get('devices', [])

        c_res = mongo_db[DEVICE_COLLECTION].find_one({'_id': ObjectId(device_id)})

        if not c_res:
            print(f"Please connect the device with ID {device_id} to the network first.")
            socketio.emit('error', {'error_msg': f"device with ID {device_id} not found."}, room=socket_id)
            return

        if device_id in devices:
            print(f"User {user_id} already has device {device_id} registered.")
            socketio.emit('error', {'error_msg': f"User {user_id} already has device {device_id} registered."},
                          room=socket_id)
            return

        devices.append(device_id)
        socketio.emit('devices', {'devices': devices}, room=socket_id)
        mongo_db[USER_COLLECTION].update_one({'_id': ObjectId(user_id)}, {'$set': {'devices': devices}})

        try:
            if r.exists(device_id):
                user_list = json.loads(r.get(device_id))
            else:
                user_list = []

            if not any(user['user_id'] == user_id for user in user_list):
                user_list.append({'user_id': user_id, 'socket_id': socket_id})
                json_data = json.dumps(user_list)
                r.set(device_id, json_data)
            else:
                socketio.emit('error', {'error_msg': f"This device is already registered to user {user_id}."},
                              room=socket_id)
        except ResponseError as e:
            print(f"Redis ResponseError: {e}")
        except Exception as e:
            print(f"Unexpected error: {e}")
        finally:
            print(f"Final value for {device_id}: {r.get(device_id)}")
    except Exception as e:
        print(f"Unexpected error: {e}")


# TODO: Convert to REST
def handle_remove_device(device_id: str, user_id: str, socket_id: str) -> None:
    """
    Removes a device from a user's account and updates Redis.

    Args:
        device_id (str): The unique identifier of the device to remove.
        user_id (str): The unique identifier of the user.
        socket_id (str): The socket ID for the current connection.

    Returns:
        None
    """
    try:
        res = mongo_db[USER_COLLECTION].find_one({'_id': ObjectId(user_id)})

        if not res:
            print(f"User with ID {user_id} not found.")
            return

        devices = res.get('devices', [])

        if device_id not in devices:
            print(f"User {user_id} does not have device {device_id} registered.")
            return

        devices.remove(device_id)
        socketio.emit('devices', {'devices': devices}, room=socket_id)
        mongo_db[USER_COLLECTION].update_one({'_id': ObjectId(user_id)}, {'$set': {'devices': devices}})

        try:
            if r.exists(device_id):
                user_list = json.loads(r.get(device_id))
                user_list = [user for user in user_list if user['user_id'] != user_id]
                json_data = json.dumps(user_list)
                if json_data != '[]':
                    r.set(device_id, json_data)
                else:
                    r.delete(device_id)
            else:
                print('device not found')
        except ResponseError as e:
            print(f"Redis ResponseError: {e}")
        except Exception as e:
            print(f"Unexpected error: {e}")
        finally:
            print(f"Final value for {device_id}: {r.get(device_id)}")
    except Exception as e:
        print(f"Unexpected error: {e}")


def handle_schedule_irrigation(device_id: str, schedule: dict) -> None:
    """
    Schedules irrigation for a specific device.

    Args:
        device_id (str): The unique identifier of the device.
        schedule (dict): The schedule for irrigation containing the type and time.

    Returns:
        None
    """
    mqtt.publish(f'{device_id}/schedule', json.dumps(schedule))


# TODO: Convert to REST
def handle_retrieve_device_data(device_id: str, socket_id: str) -> None:
    """
    Retrieves device data from the database and sends it to the client.

    Args:
        device_id (str): The unique identifier of the device.
        socket_id (str): The socket ID for the current connection.

    Returns:
        None
    """
    try:
        res = mongo_db[DEVICE_COLLECTION].find_one({'_id': ObjectId(device_id)})
        if not res:
            return
        json_data = {
            'record': res.get('record', []),
            'water_usage': res.get('water_usage', [])
        }
        socketio.emit('device_data_response', json_data, room=socket_id)
    except Exception as e:
        print(f"Unexpected error: {e}")


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
            r.set(user_key, socket_id)
        else:
            print('device not found')
    except Exception as e:
        print(f"Unexpected error: {e}")


def handle_export(device_id: str, socket_id: str) -> None:
    """
    Exports data from the device to a file.

    Args:
        device_id (str): The unique identifier of the device.
        socket_id (str): the sid of the socket connection.

    Returns:
        None
    """
    try:
        res = mongo_db[DEVICE_COLLECTION].find_one({'_id': ObjectId(device_id)})
        if not res:
            print(f"device with ID {device_id} not found.")
            return

        buf = export_to_excel(res)

        socketio.emit('export_response', {'file': buf.getvalue()}, room=socket_id)

    except bson.errors.InvalidId as e:
        print(f"Invalid device ID: {device_id}, error: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")


# TODO: Convert to REST
def handle_logout(user_id: str, device_ids: list) -> None:
    """
    Logs out a user and removes their associations with devices.

    Args:
        user_id:
        device_ids:

    Returns:
        None

    """
    try:
        user = mongo_db[USER_COLLECTION].find_one({'_id': user_id})
        if not user:
            return

        for device_id in device_ids:
            if r.exists(device_id):
                user_list = json.loads(r.get(device_id))
                user_list = [user for user in user_list if user['user_id'] != user_id]
                json_data = json.dumps(user_list)
                if json_data != '[]':
                    r.set(device_id, json_data)
                else:
                    r.delete(device_id)
    except Exception as e:
        print(f"Unexpected error: {e}")
        return


# TODO: Convert to REST
def handle_fetch_devices(user_id: str, socket_id: str) -> None:
    """
    Fetches the list of devices associated with a user.

    Args:
        user_id (str): The unique identifier of the user.
        socket_id (str): The socket ID for the current connection.

    Returns:
        None
    """
    try:
        user = mongo_db[USER_COLLECTION].find_one({'_id': ObjectId(user_id)})
        if not user:
            return

        devices = user.get('devices', [])
        socketio.emit('devices', {'devices': devices}, room=socket_id)
    except Exception as e:
        print(f"Unexpected error: {e}")
        return
