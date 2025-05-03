import jwt
import datetime
from src.utils.secrets import SECRET_KEY


def generate_token(email: str, user_id: str) -> str:
    payload = {
        'exp': datetime.datetime.now() + datetime.timedelta(days=30),
        'iat': datetime.datetime.now() - datetime.timedelta(seconds=10000),
        'email': email,
        'user_id': user_id
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm='HS256')
    return token


def decode_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        return payload
    except jwt.ExpiredSignatureError:
        return {'error': 'Token expired. Please log in again.'}
    except jwt.InvalidTokenError:
        return {'error': 'Invalid token. Please log in again.'}