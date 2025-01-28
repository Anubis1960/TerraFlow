import json
from redis.exceptions import ResponseError
from src.util.db import r, mongo_db, USER_COLLECTION, CONTROLLER_COLLECTION
from src.util.extensions import mqtt, socketio
from src.util.crypt import encrypt, decrypt
import regex as re
from bson.objectid import ObjectId
from bson.errors import InvalidId

email_regex = re.compile(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$')


def handle_connect(data) -> None:
    print(data)


def handle_disconnect(data) -> None:
    print(data)


def handle_irrigate(controller_id: str) -> None:
    json_data = {
        'irrigate': True
    }
    mqtt.publish(f'{controller_id}/irrigate', json.dumps(json_data))


def handle_add_controller(controller_id: str, user_id: str, socket_id: str) -> None:
    try:
        u_res = mongo_db[USER_COLLECTION].find_one({'_id': ObjectId(user_id)})

        print(f"User data for user {user_id}: {u_res}")

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
                print(f"Json data: {json_data}")
                r.set(controller_id, json_data)
            else:
                socketio.emit('error', {'error_msg': f"This controller is already registered to user {user_id}."},
                              room=socket_id)
        except ResponseError as e:
            print(f"Redis ResponseError: {e}")
        except Exception as e:
            print(f"Unexpected error: {e}")
        finally:
            # Print the current value of the key for debugging
            print(f"Final value for {controller_id}: {r.get(controller_id)}")
    except ValueError as e:
        print(f"ValueError: {e}")
    except InvalidId as e:
        print(f"InvalidId: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")


def handle_remove_controller(controller_id: str, user_id: str, socket_id: str) -> None:
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
    except ValueError as e:
        print(f"ValueError: {e}")
    except InvalidId as e:
        print(f"InvalidId: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")


def handle_schedule_irrigation(controller_id: str, schedule: dict) -> None:
    mqtt.publish(f'{controller_id}/schedule', json.dumps(schedule))


def handle_register(email: str, password: str) -> dict[str, str]:
    try:
        res = mongo_db[USER_COLLECTION].find({'email': email})
        users = list(res)

        if len(users) > 0:
            print('User already exists')
            return {'error_msg': 'An account with this email already exists'}

        if not email_regex.match(email):
            print('Invalid email')
            return {'error_msg': 'Invalid email'}

        encrypted_password = encrypt(password)

        user = mongo_db[USER_COLLECTION].insert_one({'email': email, 'password': encrypted_password, 'controllers': []})
        print('User created:', user.inserted_id)
        return {'user_id': str(user.inserted_id)}
    except Exception as e:
        print(f"Unexpected error: {e}")
        return {'error_msg': 'An error occurred'}


def handle_login(email: str, password: str) -> dict[str, str]:
    try:
        res = mongo_db[USER_COLLECTION].find({'email': email})
        users = list(res)

        if len(users) == 0:
            print('User not found')
            return {'error_msg': 'Invalid email or password'}

        user = users[0]
        encrypted_password = user['password']
        decrypted_password = decrypt(encrypted_password)

        if decrypted_password == password:
            print('Login successful')
            return {'user_id': str(user['_id']), 'controllers': user['controllers']}
        else:
            print('Login failed')
            return {'error_msg': 'Invalid email or password'}

    except Exception as e:
        print(f"Unexpected error: {e}")
        return {'error_msg': 'An error occurred'}


def handle_retrieve_controller_data(controller_id: str, socket_id: str) -> None:
    try:
        res = mongo_db[CONTROLLER_COLLECTION].find_one({'_id': ObjectId(controller_id)})
        if not res:
            print(f"controller with ID {controller_id} not found in database.")
            return
        print(res)
        json_data = {
            'record': res.get('record', []),
            'water_used_month': res.get('water_used_month', [])
        }
        print(f"Controller data for controller {controller_id}: {json_data} on socket {socket_id}")
        socketio.emit('controller_data_response', json_data, room=socket_id)
    except ResponseError as e:
        print(f"Redis ResponseError: {e}")
    except ValueError as e:
        print(f"ValueError: {e}")
    except InvalidId as e:
        print(f"InvalidId: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")


def remap_redis(controller_id: str, user_id: str, socket_id: str) -> None:
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
    except ResponseError as e:
        print(f"Redis ResponseError: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")
    finally:
        print(f"Final value for {controller_id}: {r.get(controller_id)}")
