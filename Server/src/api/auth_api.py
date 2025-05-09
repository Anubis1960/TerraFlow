from http import HTTPStatus

from flask import redirect, url_for, session, Blueprint, request, jsonify, current_app

from src.service.auth_service import handle_form_login, handle_token_login, handle_register, handle_logout
from src.utils.tokenizer import decode_token

auth_blueprint = Blueprint('auth', __name__)


@auth_blueprint.route('/')
def hello_world():
    email = session.get('email', None)
    return f'Hello, you are logged in as {email}!' if email else 'Hello, you are not logged in!'


@auth_blueprint.route('/login', methods=['GET', 'POST'])
def login():
    """
    Logs in the user using the provided credentials or access token.

    Returns:
        A JSON response with the user's token and controllers if successful, an error message otherwise.
    """
    print("Logging in...")
    if request.method == 'POST':
        data = request.get_json()
        if 'password' in data:
            password = data['password']
            email = data['email']
            res = handle_form_login(email, password)
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
    """
    Authorizes the user using Google OAuth.

    Returns:
        A redirect to the callback URL with the user's token if successful, an error message otherwise.

    """
    print("Authorizing...")
    google = current_app.oauth_manager.get_provider('google')
    try:
        token = google.authorize_access_token()
        # Retrieve the access token
        access_token = token['access_token']
        resp = google.get('userinfo')

        # Retrieve user data
        user_info = resp.json()
        user_email = user_info['email']
        user_name = user_info['name']

        res = handle_token_login(user_email)

        callback_url = f"http://localhost:4200/auth/callback?token={res['token'] if 'token' in res else ''}"
        return redirect(callback_url)

    except Exception as e:
        print(f"An error occurred: {e}")
        return jsonify({"error": "Internal server error"}), HTTPStatus.INTERNAL_SERVER_ERROR


@auth_blueprint.route('/register', methods=['POST'])
def register():
    """
    Registers a new user with the provided email and password.

    Returns:
        A JSON response with the user's token if successful, an error message otherwise.

    """
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


@auth_blueprint.route('/logout', methods=['POST'])
def logout():
    data = request.get_json()
    token = request.headers.get('Authorization')
    token = token.split(" ")[1] if token else None
    print('Logging out:', data)
    if 'deviceIds' in data:
        device_ids = data['deviceIds']
        decoded_token = decode_token(token)
        if 'error' in decoded_token:
            return jsonify({"error": decoded_token['error']}), HTTPStatus.UNAUTHORIZED
        user_id = decoded_token['user_id']
        res = handle_logout(user_id, device_ids)
        if 'error' in res:
            return jsonify(res), HTTPStatus.BAD_REQUEST
        else:
            return jsonify(res), HTTPStatus.OK

    return jsonify({"error": "Invalid request"}), HTTPStatus.BAD_REQUEST
