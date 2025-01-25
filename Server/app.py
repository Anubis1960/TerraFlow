import os
from flask import Flask
from src.util.extensions import socketio
import logging
from flask_mqtt import Mqtt
import src.api.test

# Flask app initialization
app = Flask(__name__)
app.config['SECRET_KEY'] = os.urandom(24)
app.config['MQTT_BROKER_URL'] = 'broker.hivemq.com'
app.config['MQTT_BROKER_PORT'] = 1883
app.config['MQTT_USERNAME'] = ''
app.config['MQTT_PASSWORD'] = ''
app.config['MQTT_REFRESH_TIME'] = 1.0  # refresh time in seconds
app.config['MQTT_TLS_ENABLED'] = False  # set TLS to disabled


# Bind socketio to the app
mqtt = Mqtt(app)
socketio.init_app(app)

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)


# Run the app
if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, use_reloader=True, debug=True)
