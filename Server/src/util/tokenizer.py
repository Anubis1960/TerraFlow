import jwt
import datetime
from src.util.config import SECRET_KEY


def generate_token(email, user_id):
    payload = {
        'exp': datetime.datetime.now() + datetime.timedelta(days=30),
        'iat': datetime.datetime.now() - datetime.timedelta(seconds=10000),
        'email': email,
        'user_id': user_id
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm='HS256')
    return token


def decode_token(token):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        return payload
    except jwt.ExpiredSignatureError:
        return 'Signature expired. Please log in again.'
    except jwt.InvalidTokenError:
        return 'Invalid token. Please log in again.'


if __name__ == '__main__':
    email = "test@example.com"
    user_id = "12345"
    token = generate_token(email, user_id)
    decoded_token = decode_token(token)
    print('Decoded token:', decoded_token)