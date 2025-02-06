from src.util.config import GOOGLE_CLIENT_ID
from src.util.db import mongo_db, USER_COLLECTION
from src.util.crypt import encrypt
from src.util.tokenizer import generate_token
import regex as re
from google.oauth2 import id_token
from google.auth.transport import requests, Request

email_regex = re.compile(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$')


def login(email: str, password: str) -> dict:
    user = mongo_db[USER_COLLECTION].find_one({"email": email})
    if user:
        if user['password'] == encrypt(password):
            return {'token': generate_token(email, str(user['_id']))}
    return {'error': 'Invalid credentials'}


def register(email: str, password: str) -> dict:
    if not email_regex.match(email):
        return {'error': 'Invalid email address'}

    user = mongo_db[USER_COLLECTION].find_one({"email": email})
    if user:
        return {'error': 'User already exists'}

    user_id = mongo_db[USER_COLLECTION].insert_one({ 'email': email, 'password': encrypt(password) }).inserted_id
    return {'token': generate_token(email, str(user_id))}


def google_auth(request: Request) -> dict:
    id_token_str = request.form.get('id_token')
    if not id_token_str:
        return {'error': 'No ID token provided'}
    try:
        id_info = id_token_str.verify_oauth2_token(id_token_str, requests.Request(), GOOGLE_CLIENT_ID)
        email = id_info['email']
        user = mongo_db[USER_COLLECTION].find_one({"email": email})
        if user:
            return {'token': generate_token(email, str(user['_id']))}
        else:
            user_id = mongo_db[USER_COLLECTION].insert_one({ 'email': email }).inserted_id
            return {'token': generate_token(email, str(user_id))}
    except ValueError:
        return {'error': 'Invalid ID token'}
    except Exception as e:
        return {'error': f'An error occurred: {e}'}
