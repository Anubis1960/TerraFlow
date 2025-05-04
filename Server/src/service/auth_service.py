import json

import regex as re

from src.config.mongo import mongo_db, USER_COLLECTION
from src.config.redis import r
from src.utils.crypt import encrypt, decrypt
from src.utils.tokenizer import generate_token

email_regex = re.compile(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$')


def handle_form_login(email: str, password: str) -> dict:
    """
    Handle login with email and password.

    Args:
        email: str: The email of the user.
        password: str: The password of the user.

    Returns:
        dict: A dictionary containing the token and devices associated with the user.

    """
    try:
        res = mongo_db[USER_COLLECTION].find({'email': email})
        users = list(res)

        print(users)

        if len(users) == 0:
            return {'error': 'Invalid email or password'}

        user = users[0]
        encrypted_password = user['password']
        decrypted_password = decrypt(encrypted_password)

        if decrypted_password == password:
            token = generate_token(email, str(user['_id']))
            return {'token': token, 'devices': user['devices']}
        else:
            return {'error': 'Invalid email or password'}
    except Exception as e:
        return {'error': f'An error occurred: {e}'}


def handle_token_login(email: str) -> dict:
    """
    Handle login with an access token.

    Args:
        email: str: The email of the user.

    Returns:
        dict: A dictionary containing the token and devices associated with the user.
    """
    user = mongo_db[USER_COLLECTION].find_one({"email": email})
    if user:
        return {'token': generate_token(email, str(user['_id']))}
    else:
        user_id = mongo_db[USER_COLLECTION].insert_one({'email': email}).inserted_id
        return {'token': generate_token(email, str(user_id))}


def handle_register(email: str, password: str) -> dict:
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


def handle_logout(user_id: str, deviceIds: str) -> dict:

    """
    Handle logout for a user.

    Args:
        user_id: str: The ID of the user.
        deviceIds: str: The IDs of the devices to be logged out.

    Returns:
        dict: A dictionary indicating success or failure of the logout operation.
    """
    try:
        user = mongo_db[USER_COLLECTION].find_one({'_id': user_id})
        print("User:", user)
        if not user:
            return {'error': 'User not found'}

        for device_id in deviceIds:
            device_key = f"device:{device_id}"
            if r.exists(device_key):
                user_list = json.loads(r.get(device_key))
                print("Before:", user_list)
                user_list = [user for user in user_list if user != user_id]
                print("After:", user_list)
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
