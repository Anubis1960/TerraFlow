import json
from google.auth.transport import (requests as google_requests, Request)
from src.utils.secrets import GOOGLE_CLIENT_ID
from bson import ObjectId
import string
import secrets
import regex as re

from src.config.mongo import mongo_db, USER_COLLECTION, DEVICE_COLLECTION
from src.config.redis import r
from src.utils.crypt import encrypt, decrypt
from src.utils.tokenizer import generate_token

email_regex = re.compile(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$')


def handle_form_login(email: str, password: str) -> dict:
    """
    Handle login with email and password.

    :param email: str: The email of the user.
    :param password: str: The password of the user.
    :return: dict: A dictionary containing the token and devices associated with the user, or an error message.
    """
    try:
        res = mongo_db[USER_COLLECTION].find({'email': email})
        users = list(res)

        if len(users) == 0:
            return {'error': 'Invalid email or password'}

        user = users[0]
        encrypted_password = user['password']
        decrypted_password = decrypt(encrypted_password)

        devices = user.get('devices', [])
        device_data = []
        for device_id in devices:
            device = mongo_db[DEVICE_COLLECTION].find_one({"_id": ObjectId(device_id)})
            if device:
                device_data.append({
                    'id': str(device['_id']),
                    'name': device.get('name', 'Unknown Device'),
                })

        if decrypted_password == password:
            token = generate_token(email, str(user['_id']))
            return {'token': token, 'devices': device_data}
        else:
            return {'error': 'Invalid email or password'}
    except Exception as e:
        return {'error': f'An error occurred: {e}'}


def handle_token_login(email: str) -> dict:
    """
    Handle login with an access token.

    :param email: str: The email of the user.
    :return: dict: A dictionary containing the token if the user exists, or creates a new user and returns the token.
    """
    user = mongo_db[USER_COLLECTION].find_one({"email": email})
    if user:
        token = generate_token(email, str(user['_id']))
        return {'token': token}
    else:
        alphabet = string.ascii_letters + string.digits
        password = ''.join(secrets.choice(alphabet) for i in range(20))
        user = mongo_db[USER_COLLECTION].insert_one({'email': email, 'password': encrypt(password), 'devices': []})
        token = generate_token(email, str(user.inserted_id))
        return {'token': token}


def google_auth(request: Request) -> dict:
    """
    Authorizes the user using Google OAuth.

    :param request: Request: The request object.
    :return: dict: A dictionary containing the token if the user exists, or creates a new user and returns the token.
    """
    id_token_str = request.form.get('id_token')
    if not id_token_str:
        return {'error': 'No ID token provided'}
    try:
        id_info = id_token_str.verify_oauth2_token(id_token_str, google_requests.Request(), GOOGLE_CLIENT_ID)
        email = id_info['email']
        res = handle_token_login(email)
        return res
    except ValueError:
        return {'error': 'Invalid ID token'}
    except Exception as e:
        return {'error': f'An error occurred: {e}'}


def handle_register(email: str, password: str) -> dict:
    """
    Handle user registration.

    :param email: str: The email of the user.
    :param password: str: The password of the user.
    :return: dict: A dictionary containing the token if registration is successful, or an error message.
    """
    try:
        res = mongo_db[USER_COLLECTION].find({'email': email})
        users = list(res)

        if len(users) > 0:
            return {'error_msg': 'An account with this email already exists'}

        if not email_regex.match(email):
            return {'error': 'Invalid email'}

        encrypted_password = encrypt(password)

        user = mongo_db[USER_COLLECTION].insert_one({'email': email, 'password': encrypted_password, 'devices': []})
        token = generate_token(email, str(user.inserted_id))
        return {'token': token}
    except Exception as e:
        print(f"Unexpected error: {e}")
        return {'error': 'An error occurred'}


def handle_logout(user_id: str, deviceIds: list) -> dict:
    """
    Handle logout for a user.

    :param user_id: str: The ID of the user.
    :param deviceIds: str: The IDs of the devices to be logged out.
    :return: dict: A dictionary indicating success or an error message.
    """
    try:
        user = mongo_db[USER_COLLECTION].find_one({'_id': ObjectId(user_id)})
        if not user:
            return {'error': 'User not found'}

        for device_id in deviceIds:
            device_key = f"device:{device_id}"
            if r.exists(device_key):
                user_list = json.loads(r.get(device_key))
                user_list = [user for user in user_list if user != user_id]
                json_data = json.dumps(user_list)
                if json_data != '[]':
                    r.set(device_key, json_data)
                else:
                    r.delete(device_key)
            else:
                print(f"Device with ID {device_id} not found.")

        return {'success': True}
    except Exception as e:
        print(f"Unexpected error: {e}")
        return {'error': 'An error occurred'}
