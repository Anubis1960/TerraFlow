from http import HTTPStatus
from urllib.parse import urlencode

from flask import redirect, url_for, session, Blueprint, request, jsonify, current_app


auth_blueprint = Blueprint('auth', __name__)
@auth_blueprint.route('/')
def hello_world():
    email = session.get('email', None)
    return f'Hello, you are logged in as {email}!' if email else 'Hello, you are not logged in!'

@auth_blueprint.route('/login', methods=['GET'])
def login():
    google = current_app.oauth_manager.get_provider('google')
    redirect_uri = url_for('auth.authorize', _external=True)
    return google.authorize_redirect(redirect_uri)

@auth_blueprint.route('/authorize', methods=['GET'])
def authorize():
    print("Authorizing...")
    google = current_app.oauth_manager.get_provider('google')
    print(google)
    try:
        token = google.authorize_access_token()
        print(token)
        if not token:
            return jsonify({"error": "Access denied or token not received"}), HTTPStatus.BAD_REQUEST

        resp = google.get('userinfo')
        if resp.status_code != HTTPStatus.OK:
            return jsonify({"error": "Failed to fetch user info"}), HTTPStatus.BAD_REQUEST

        user_info = resp.json()
        session['email'] = user_info['email']

        query_params = urlencode({
            'email': user_info['email'],
        })

        callback_url = f"http://localhost:4200/auth/callback?{query_params}"
        print(callback_url)
        return redirect(callback_url)

    except Exception as e:
        print(f"An error occurred: {e}")
        return jsonify({"error": "Internal server error"}), HTTPStatus.INTERNAL_SERVER_ERROR