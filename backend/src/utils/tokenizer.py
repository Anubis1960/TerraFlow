import jwt
import datetime
from src.utils.secrets import SECRET_KEY


def validate_header(headers) -> str or None:
    """
    Validate the request header to ensure it contains a valid token.

    :param headers: dict: The request headers containing the Authorization token.
    :return: bool: True if the header is valid, False otherwise.
    """
    if 'Authorization' not in headers:
        return None
    token = headers['Authorization'].split(" ")[1] if ' ' in headers['Authorization'] else None
    if not token:
        return None
    try:
        payload = decode_token(token)
        if 'error' in payload:
            return None
        if 'user_id' not in payload:
            return None
        return payload['user_id']
    except jwt.InvalidTokenError:
        return None


def generate_token(email: str, user_id: str) -> str:
    """
    Generate a JWT token with an expiration time of 30 days.

    :param email: str: The user's email address.
    :param user_id: str: The user's unique identifier.
    :return: str: A JWT token as a string.
    """
    payload = {
        'exp': datetime.datetime.now(tz=datetime.timezone.utc) + datetime.timedelta(days=30),
        'iat': datetime.datetime.now(tz=datetime.timezone.utc) - datetime.timedelta(seconds=10000),
        'email': email,
        'user_id': user_id
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm='HS256')
    return token


def decode_token(token: str) -> dict:
    """
    Decode a JWT token and return the payload.

    :param token: str: The JWT token to decode.
    :return: dict: The decoded payload if the token is valid, or an error message if invalid.
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        return payload
    except jwt.ExpiredSignatureError:
        return {'error': 'Token expired. Please log in again.'}
    except jwt.InvalidTokenError:
        return {'error': 'Invalid token. Please log in again.'}
