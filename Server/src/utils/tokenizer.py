import jwt
import datetime
from src.utils.secrets import SECRET_KEY


def generate_token(email: str, user_id: str) -> str:
    payload = {
        'exp': datetime.datetime.now(tz=datetime.timezone.utc) + datetime.timedelta(days=30),
        'iat': datetime.datetime.now(tz=datetime.timezone.utc) - datetime.timedelta(seconds=10000),
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


if __name__ == '__main__':
    token = generate_token("1@1.1", "681785b2abcafa0ae18c75f9")
    print(token)
    decoded = decode_token(token)
    print(decoded)