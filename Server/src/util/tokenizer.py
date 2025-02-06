import jwt
import datetime
from src.util.config import SECRET_KEY


def generate_token(email, user_id):
    payload = {
        'exp': datetime.datetime.now() + datetime.timedelta(days=30),
        'iat': datetime.datetime.now(),
        'email': email,
        'user_id': user_id
    }
    return jwt.encode(payload, SECRET_KEY, algorithm='HS256')


def decode_token(token):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        return payload
    except jwt.ExpiredSignatureError:
        return 'Signature expired. Please log in again.'
    except jwt.InvalidTokenError:
        return 'Invalid token. Please log in again.'
