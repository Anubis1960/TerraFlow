from http import HTTPStatus
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from flask import Blueprint, request, jsonify
from src.service.rest_service import login, register, google_auth
from src.util.config import GOOGLE_CLIENT_ID

auth_blueprint = Blueprint('auth', __name__, url_prefix='/auth')


@auth_blueprint.route('/login', methods=['POST'])
def handle_login():
    data = request.json
    if 'email' not in data or 'password' not in data:
        return jsonify({'message': 'Email and password are required'}), HTTPStatus.BAD_REQUEST
    email = data['email']
    password = data['password']
    res = login(email, password)
    if 'error' in res:
        return jsonify(res), HTTPStatus.UNAUTHORIZED
    return jsonify(res), HTTPStatus.OK


@auth_blueprint.route('/register', methods=['POST'])
def handle_register():
    data = request.json
    if 'email' not in data or 'password' not in data:
        return jsonify({'message': 'Email and password are required'}), HTTPStatus.BAD_REQUEST
    email = data['email']
    password = data['password']

    res = register(email, password)

    if 'error' in res:
        return jsonify(res), HTTPStatus.BAD_REQUEST

    return jsonify(res), HTTPStatus.CREATED


@auth_blueprint.route('/google', methods=['POST'])
def handle_google_auth():
    res = google_auth(request)

    if 'error' in res:
        return jsonify(res), HTTPStatus.UNAUTHORIZED

    return jsonify(res), HTTPStatus.OK


@auth_blueprint.route('/verify-google-token', methods=['POST'])
def verify_google_token():
    print("Handling Google token verification")
    print(request.form)
    access_token = request.form.get('access_token')

    if not access_token:
        return jsonify({'error': 'No access token provided'}), HTTPStatus.BAD_REQUEST

    try:
        id_info = id_token.verify_oauth2_token(access_token, google_requests.Request(), GOOGLE_CLIENT_ID)
        return jsonify(id_info), HTTPStatus.OK
    except ValueError:
        return jsonify({'error': 'Invalid ID token'}), HTTPStatus.UNAUTHORIZED
    except Exception as e:
        return jsonify({'error': f'An error occurred: {e}'}), HTTPStatus.INTERNAL_SERVER_ERROR
