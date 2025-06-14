from flask import Flask
from flask_cors import CORS
import src.api.mqtt_api
import src.api.socket_api
from src.model.oauth_manager import OAuthManager
from src.utils.secrets import (MQTT_BROKER, MQTT_PORT, MQTT_USERNAME, MQTT_PASSWORD, HOST, PORT, SECRET_KEY)
from src.config.protocol import socketio, mqtt, oauth
from src.api.auth_api import auth_blueprint
from src.api.device_api import device_blueprint
from src.middleware.error_handle import error_handle_blueprint
from src.api.user_api import user_blueprint
from src.config.scheduler import start_scheduler


app = Flask(__name__)

CORS(app)
app.secret_key = SECRET_KEY
app.config['MQTT_BROKER_URL'] = MQTT_BROKER
app.config['MQTT_BROKER_PORT'] = MQTT_PORT
app.config['MQTT_USERNAME'] = MQTT_USERNAME
app.config['MQTT_PASSWORD'] = MQTT_PASSWORD
app.config['MQTT_REFRESH_TIME'] = 1.0
app.config['MQTT_TLS_ENABLED'] = False

oauth_manager = OAuthManager(app)
app.oauth_manager = oauth_manager

app.register_blueprint(error_handle_blueprint)
app.register_blueprint(auth_blueprint)
app.register_blueprint(device_blueprint)
app.register_blueprint(user_blueprint)

# Bind socketio to the app
socketio.init_app(app)
mqtt.init_app(app)

mqtt.subscribe('register')
start_scheduler()

# Run the app
if __name__ == '__main__':
    # app.run(debug=True, host=HOST, port=PORT)
    socketio.run(app, host=HOST, port=PORT, use_reloader=True, debug=True)
