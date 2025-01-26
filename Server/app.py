import os
from flask import Flask
from src.util.extensions import socketio, mqtt
import logging
import src.api.socket_api
import src.api.mqtt_api
from env import HOST, PORT, MQTT_PORT, MQTT_BROKER

# Flask app initialization
app = Flask(__name__)
app.config['SECRET_KEY'] = os.urandom(24)
app.config['MQTT_BROKER_URL'] = MQTT_BROKER
app.config['MQTT_BROKER_PORT'] = MQTT_PORT
app.config['MQTT_USERNAME'] = ''
app.config['MQTT_PASSWORD'] = ''
app.config['MQTT_REFRESH_TIME'] = 1.0  # refresh time in seconds
app.config['MQTT_TLS_ENABLED'] = False  # set TLS to disabled


# Bind socketio to the app
socketio.init_app(app)
mqtt.init_app(app)

mqtt.subscribe('register')

# Configure logging
# logging.basicConfig(
#     level=logging.DEBUG,
#     format='%(levelname)s - %(message)s',
#     handlers=[logging.StreamHandler()]
# )


# Run the app
if __name__ == '__main__':
    socketio.run(app, host=HOST, port=PORT, use_reloader=False, debug=True)
