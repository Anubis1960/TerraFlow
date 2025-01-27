import json
from redis.exceptions import ResponseError
from src.util.db import r, mongo_db, USER_COLLECTION, CONTROLLER_COLLECTION
from src.util.extensions import mqtt, socketio
from src.util.crypt import encrypt, decrypt
import regex as re

email_regex = re.compile(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$')


def handle_connect(data) -> None:
    print(data)


def handle_disconnect(data) -> None:
    print(data)


def handle_irrigate(device_id: str) -> None:
    json_data = {
        'irrigate': True
    }
    mqtt.publish(f'{device_id}/irrigate', json.dumps(json_data))


def handle_add_device(device_id: str, user_id: str, socket_id: str) -> None:

    res = mongo_db[CONTROLLER_COLLECTION].find_one({'_id': device_id})

    if not res:
        print(f"Please connect the device with ID {device_id} to the network first.")
        socketio.emit('error', {'message': f"Device with ID {device_id} not found."}, room=socket_id)
        return

    try:
        if r.exists(device_id):
            user_list = json.loads(r.get(device_id))
        else:
            user_list = []

        if not any(user['user_id'] == user_id for user in user_list):
            user_list.append({'user_id': user_id, 'socket_id': socket_id})
            json_data = json.dumps(user_list)
            print(f"Json data: {json_data}")
            r.set(device_id, json_data)
        else:
            socketio.emit('error', {'message': f"This device is already registered to user {user_id}."}, room=socket_id)
    except ResponseError as e:
        print(f"Redis ResponseError: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")
    finally:
        # Print the current value of the key for debugging
        print(f"Final value for {device_id}: {r.get(device_id)}")


def handle_remove_device(device_id: str, user_id: str) -> None:
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
            print('Device not found')
    except ResponseError as e:
        print(f"Redis ResponseError: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")
    finally:
        print(f"Final value for {device_id}: {r.get(device_id)}")


def handle_schedule_irrigation(device_id: str, schedule: dict) -> None:
    mqtt.publish(f'{device_id}/schedule', json.dumps(schedule))


def handle_register(email: str, password: str) -> dict[str, str]:
    try:
        res = mongo_db[USER_COLLECTION].find({'email': email})
        users = list(res)

        if len(users) > 0:
            print('User already exists')
            return {'error': 'An account with this email already exists'}

        if not email_regex.match(email):
            print('Invalid email')
            return {'error': 'Invalid email'}

        encrypted_password = encrypt(password)

        user = mongo_db[USER_COLLECTION].insert_one({'email': email, 'password': encrypted_password})
        print('User created:', user.inserted_id)
        return {'user_id': str(user.inserted_id)}
    except Exception as e:
        print(f"Unexpected error: {e}")
        return {'error': 'An error occurred'}


def handle_login(email: str, password: str) -> dict[str, str]:
    try:
        res = mongo_db[USER_COLLECTION].find({'email': email})
        users = list(res)

        if len(users) == 0:
            print('User not found')
            return {'error': 'Invalid email or password'}

        user = users[0]
        encrypted_password = user['password']
        decrypted_password = decrypt(encrypted_password)

        if decrypted_password == password:
            print('Login successful')
            return {'user_id': str(user['_id'])}
        else:
            print('Login failed')
            return {'error': 'Invalid email or password'}

    except Exception as e:
        print(f"Unexpected error: {e}")
        return {'error': 'An error occurred'}
