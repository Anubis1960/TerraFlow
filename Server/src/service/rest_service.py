import regex as re
from google.auth.transport import (requests as google_requests, Request)

from src.utils.secrets import GOOGLE_CLIENT_ID
from src.utils.crypt import encrypt, decrypt
from src.config.mongo import mongo_db, USER_COLLECTION
from src.utils.tokenizer import generate_token

email_regex = re.compile(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$')


def handle_simple_login(email: str, password: str) -> dict:
    """
    Handle login with email and password.

    Args:
        email: str: The email of the user.
        password: str: The password of the user.

    Returns:
        dict: A dictionary containing the token and controllers associated with the user.

    """
    try:
        res = mongo_db[USER_COLLECTION].find({'email': email})
        users = list(res)

        if len(users) == 0:
            return {'error_msg': 'Invalid email or password'}

        user = users[0]
        encrypted_password = user['password']
        decrypted_password = decrypt(encrypted_password)

        if decrypted_password == password:
            token = generate_token(email, str(user['_id']))
            return {'token': token, 'controllers': user['controllers']}
        else:
            return {'error_msg': 'Invalid email or password'}
    except Exception as e:
        return {'error_msg': f'An error occurred: {e}'}


def handle_token_login(email: str) -> dict:
    """
    Handle login with an access token.

    Args:
        email: str: The email of the user.

    Returns:
        dict: A dictionary containing the token and controllers associated with the user.
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
            return {'error_msg': 'Invalid email'}

        encrypted_password = encrypt(password)

        user = mongo_db[USER_COLLECTION].insert_one({'email': email, 'password': encrypted_password, 'controllers': []})
        token = generate_token(email, str(user.inserted_id))
        return {'token': token}
    except Exception as e:
        print(f"Unexpected error: {e}")
        return {'error_msg': 'An error occurred'}


def google_auth(request: Request) -> dict:
    """
    Authorizes the user using Google OAuth.

    Args:
        request: Request: The request object.

    Returns:
        dict: A dictionary containing the token and controllers associated with the user.

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
