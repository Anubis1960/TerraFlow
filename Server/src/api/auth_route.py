from http import HTTPStatus
from urllib.parse import urlencode

from flask import redirect, url_for, session, Blueprint, request, jsonify, current_app
from paho.mqtt.subscribe import callback

auth_blueprint = Blueprint('auth', __name__)

@auth_blueprint.route('/')
def hello_world():
    """
    A test route to check if the user is logged in.

    This route simply returns a message with the logged-in user's email, if available.

    Returns:
        str: A greeting message with the logged-in user's email, or a default message.
    """
    email = dict(session).get('email', None)
    return f'Hello, you are logged in as {email}!' if email else 'Hello, you are not logged in!'


@auth_blueprint.route('/login', methods=['GET', 'POST'])
def login() -> jsonify:
    if request.method == 'POST':
        pass
    else:
        # Handle case when the user logs in via OAuth2.0
        google = current_app.oauth_manager.get_provider('google')
        redirect_uri = url_for('auth.authorize', _external=True)
        return google.authorize_redirect(redirect_uri)


@auth_blueprint.route('/authorize')
def authorize() -> jsonify:
    google = current_app.oauth_manager.get_provider('google')
    token = google.authorize_access_token()

    # Retrieve the access token
    access_token = token['access_token']
    resp = google.get('userinfo')

    # Retrieve user data
    user_info = resp.json()
    user_email = user_info['email']
    user_name = user_info['name']

    query_params = urlencode({
        'email': user_email,
        'name': user_name
    })

    callback_url = f"http://localhost:4200/auth/callback?{query_params}"
    return redirect(callback_url)