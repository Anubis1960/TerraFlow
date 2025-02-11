from http import HTTPStatus
from urllib.parse import urlencode
from flask import redirect, url_for, session, Blueprint, request, jsonify, current_app
from src.service.rest_service import handle_simple_login, handle_token_login, handle_register
from src.util.tokenizer import generate_token

auth_blueprint = Blueprint('auth', __name__)
@auth_blueprint.route('/')
def hello_world():
    email = session.get('email', None)
    return f'Hello, you are logged in as {email}!' if email else 'Hello, you are not logged in!'


@auth_blueprint.route('/login', methods=['GET', 'POST'])
def login():
    print("Logging in...")
    print(f"Request method: {request.method}")
    if request.method == 'POST':
        data = request.get_json()
        if 'password' in data:
            password = data['password']
            email = data['email']
            print(f"Email: {email}, Password: {password}")
            res = handle_simple_login(email, password)
            print(f"Response: {res}")
            if 'error' in res:
                return jsonify(res), HTTPStatus.BAD_REQUEST
            else:
                return jsonify(res), HTTPStatus.OK
        elif 'access_token' in data:
            access_token = data['access_token']
            print(f"Access token: {access_token}")
            email = data['email']
            res = handle_token_login(email)
            print(f"Response: {res}")
            if 'error' in res:
                return jsonify(res), HTTPStatus.BAD_REQUEST
            else:
                return jsonify(res), HTTPStatus.OK
    else:
        google = current_app.oauth_manager.get_provider('google')
        redirect_uri = url_for('auth.authorize', _external=True)
        print(f"Redirect URI: {redirect_uri}")  # Debugging
        return google.authorize_redirect(redirect_uri)

    return jsonify({"error": "Invalid request"}), HTTPStatus.BAD_REQUEST

@auth_blueprint.route('/authorize', methods=['GET'])
def authorize():
    print("Authorizing...")
    google = current_app.oauth_manager.get_provider('google')
    print(google)
    try:
        token = google.authorize_access_token()
        # Retrieve the access token
        access_token = token['access_token']
        resp = google.get('userinfo')

        # Retrieve user data
        user_info = resp.json()
        user_email = user_info['email']
        user_name = user_info['name']

        print(f"User info: {user_info}, {user_email}, {user_name}, {access_token}, {resp}")

        res = handle_token_login(user_email)

        callback_url = f"http://localhost:4200/auth/callback?token={res['token'] if 'token' in res else ''}"
        return redirect(callback_url)

    except Exception as e:
        print(f"An error occurred: {e}")
        return jsonify({"error": "Internal server error"}), HTTPStatus.INTERNAL_SERVER_ERROR


@auth_blueprint.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    if 'password' in data and 'email' in data:
        password = data['password']
        email = data['email']
        res = handle_register(email, password)
        if 'error' in res:
            return jsonify(res), HTTPStatus.BAD_REQUEST
        else:
            return jsonify(res), HTTPStatus.OK
    return jsonify({"error": "Invalid request"}), HTTPStatus.BAD_REQUEST