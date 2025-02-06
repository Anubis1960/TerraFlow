from flask import Flask
from flask_cors import CORS

import src.api.rest_api
import src.api.mqtt_api
import src.api.socket_api
from src.util.config import MQTT_BROKER, MQTT_PORT, HOST, PORT, SECRET_KEY, GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET
from src.util.extensions import socketio, mqtt

app = Flask(__name__)

CORS(app)
app.config['SECRET_KEY'] = SECRET_KEY
app.config['MQTT_BROKER_URL'] = MQTT_BROKER
app.config['MQTT_BROKER_PORT'] = MQTT_PORT
app.config['MQTT_USERNAME'] = ''
app.config['MQTT_PASSWORD'] = ''
app.config['MQTT_REFRESH_TIME'] = 1.0
app.config['MQTT_TLS_ENABLED'] = False
app.config['OAUTH2_PROVIDERS'] = {
    'google': {
        'client_id': GOOGLE_CLIENT_ID,
        'client_secret': GOOGLE_CLIENT_SECRET,
        'authorize_url': 'https://accounts.google.com/o/oauth2/auth',
        'access_token_url': 'https://accounts.google.com/o/oauth2/token',
        'userinfo_url': {
            'url': 'https://www.googleapis.com/oauth2/v3/userinfo',
            'email': lambda json: json['email'],
        },
        'scope': 'email profile',
    }
}


app.register_blueprint(src.api.rest_api.auth_blueprint)


# Bind socketio to the app
socketio.init_app(app)
mqtt.init_app(app)

mqtt.subscribe('register')

# Run the app
if __name__ == '__main__':
    socketio.run(app, host=HOST, port=PORT, use_reloader=False, debug=True)
