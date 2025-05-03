"""
Service handlers for IoT irrigation controllers, including user management, controller interaction,
and irrigation scheduling.

### Functions:
1. **handle_connect** - Handles the event when a client connects.
2. **handle_disconnect** - Handles the event when a client disconnects.
3. **handle_irrigate** - Triggers an irrigation event for a specific controller.
4. **handle_add_controller** - Adds a controller to a user's account and updates Redis.
5. **handle_remove_controller** - Removes a controller from a user's account and updates Redis.
6. **handle_schedule_irrigation** - Schedules irrigation for a specific controller.
7. **handle_register** - Registers a new user.
8. **handle_login** - Logs in an existing user.
9. **handle_retrieve_controller_data** - Retrieves controller data from the database and sends it to the client.
10. **remap_redis** - Updates Redis with new user-controller associations.
"""

import json

import bson.errors
import regex as re
from bson.objectid import ObjectId
from redis.exceptions import ResponseError
from src.config.mongo import mongo_db, CONTROLLER_COLLECTION, USER_COLLECTION
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


def handle_irrigate(controller_id: str) -> None:
    """
    Triggers an irrigation event for a specific controller.

    Args:
        controller_id (str): The unique identifier of the controller to trigger irrigation for.

    Returns:
        None
    """
    json_data = {
        'irrigate': True
    }
    mqtt.publish(f'{controller_id}/irrigate', json.dumps(json_data))


def handle_add_controller(controller_id: str, user_id: str, socket_id: str) -> None:
    """
    Adds a controller to a user's account and updates Redis.

    Args:
        controller_id (str): The unique identifier of the controller to add.
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
        
        controllers = u_res.get('controllers', [])

        c_res = mongo_db[CONTROLLER_COLLECTION].find_one({'_id': ObjectId(controller_id)})

        if not c_res:
            print(f"Please connect the controller with ID {controller_id} to the network first.")
            socketio.emit('error', {'error_msg': f"controller with ID {controller_id} not found."}, room=socket_id)
            return

        if controller_id in controllers:
            print(f"User {user_id} already has controller {controller_id} registered.")
            socketio.emit('error', {'error_msg': f"User {user_id} already has controller {controller_id} registered."},
                          room=socket_id)
            return

        controllers.append(controller_id)
        socketio.emit('controllers', {'controllers': controllers}, room=socket_id)
        mongo_db[USER_COLLECTION].update_one({'_id': ObjectId(user_id)}, {'$set': {'controllers': controllers}})

        try:
            if r.exists(controller_id):
                user_list = json.loads(r.get(controller_id))
            else:
                user_list = []

            if not any(user['user_id'] == user_id for user in user_list):
                user_list.append({'user_id': user_id, 'socket_id': socket_id})
                json_data = json.dumps(user_list)
                r.set(controller_id, json_data)
            else:
                socketio.emit('error', {'error_msg': f"This controller is already registered to user {user_id}."},
                              room=socket_id)
        except ResponseError as e:
            print(f"Redis ResponseError: {e}")
        except Exception as e:
            print(f"Unexpected error: {e}")
        finally:
            print(f"Final value for {controller_id}: {r.get(controller_id)}")
    except Exception as e:
        print(f"Unexpected error: {e}")


def handle_remove_controller(controller_id: str, user_id: str, socket_id: str) -> None:
    """
    Removes a controller from a user's account and updates Redis.

    Args:
        controller_id (str): The unique identifier of the controller to remove.
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

        controllers = res.get('controllers', [])

        if controller_id not in controllers:
            print(f"User {user_id} does not have controller {controller_id} registered.")
            return

        controllers.remove(controller_id)
        socketio.emit('controllers', {'controllers': controllers}, room=socket_id)
        mongo_db[USER_COLLECTION].update_one({'_id': ObjectId(user_id)}, {'$set': {'controllers': controllers}})

        try:
            if r.exists(controller_id):
                user_list = json.loads(r.get(controller_id))
                user_list = [user for user in user_list if user['user_id'] != user_id]
                json_data = json.dumps(user_list)
                if json_data != '[]':
                    r.set(controller_id, json_data)
                else:
                    r.delete(controller_id)
            else:
                print('controller not found')
        except ResponseError as e:
            print(f"Redis ResponseError: {e}")
        except Exception as e:
            print(f"Unexpected error: {e}")
        finally:
            print(f"Final value for {controller_id}: {r.get(controller_id)}")
    except Exception as e:
        print(f"Unexpected error: {e}")


def handle_schedule_irrigation(controller_id: str, schedule: dict) -> None:
    """
    Schedules irrigation for a specific controller.

    Args:
        controller_id (str): The unique identifier of the controller.
        schedule (dict): The schedule for irrigation containing the type and time.

    Returns:
        None
    """
    mqtt.publish(f'{controller_id}/schedule', json.dumps(schedule))


def handle_retrieve_controller_data(controller_id: str, socket_id: str) -> None:
    """
    Retrieves controller data from the database and sends it to the client.

    Args:
        controller_id (str): The unique identifier of the controller.
        socket_id (str): The socket ID for the current connection.

    Returns:
        None
    """
    try:
        res = mongo_db[CONTROLLER_COLLECTION].find_one({'_id': ObjectId(controller_id)})
        if not res:
            return
        json_data = {
            'record': res.get('record', []),
            'water_usage': res.get('water_usage', [])
        }
        socketio.emit('controller_data_response', json_data, room=socket_id)
    except Exception as e:
        print(f"Unexpected error: {e}")


def remap_redis(controller_id: str, user_id: str, socket_id: str) -> None:
    """
    Updates Redis with new user-controller associations.

    Args:
        controller_id (str): The unique identifier of the controller.
        user_id (str): The unique identifier of the user.
        socket_id (str): The socket ID for the current connection.

    Returns:
        None
    """
    try:
        if r.exists(controller_id):
            user_list = json.loads(r.get(controller_id))
            user_list = [user for user in user_list if user['user_id'] != user_id]
            user_list.append({'user_id': user_id, 'socket_id': socket_id})
            json_data = json.dumps(user_list)
            if json_data != '[]':
                r.set(controller_id, json_data)
            else:
                r.delete(controller_id)
        else:
            print('controller not found')
    except Exception as e:
        print(f"Unexpected error: {e}")


def handle_export(controller_id: str, socket_id: str) -> None:
    """
    Exports data from the controller to a file.

    Args:
        controller_id (str): The unique identifier of the controller.
        socket_id (str): the sid of the socket connection.

    Returns:
        None
    """
    try:
        res = mongo_db[CONTROLLER_COLLECTION].find_one({'_id': ObjectId(controller_id)})
        if not res:
            print(f"Controller with ID {controller_id} not found.")
            return

        buf = export_to_excel(res)

        socketio.emit('export_response', {'file': buf.getvalue()}, room=socket_id)

    except bson.errors.InvalidId as e:
        print(f"Invalid controller ID: {controller_id}, error: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")


def handle_logout(user_id: str, controller_ids: list) -> None:
    """
    Logs out a user and removes their associations with controllers.

    Args:
        user_id:
        controller_ids:

    Returns:
        None

    """
    try:
        user = mongo_db[USER_COLLECTION].find_one({'_id': user_id})
        if not user:
            return

        for controller_id in controller_ids:
            if r.exists(controller_id):
                user_list = json.loads(r.get(controller_id))
                user_list = [user for user in user_list if user['user_id'] != user_id]
                json_data = json.dumps(user_list)
                if json_data != '[]':
                    r.set(controller_id, json_data)
                else:
                    r.delete(controller_id)
    except Exception as e:
        print(f"Unexpected error: {e}")
        return


def handle_fetch_controllers(user_id: str, socket_id: str) -> None:
    """
    Fetches the list of controllers associated with a user.

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

        controllers = user.get('controllers', [])
        socketio.emit('controllers', {'controllers': controllers}, room=socket_id)
    except Exception as e:
        print(f"Unexpected error: {e}")
        return
