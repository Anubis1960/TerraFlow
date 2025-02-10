from flask import Flask
from flask_cors import CORS
import src.api.mqtt_api
import src.api.socket_api
from src.model.oauth_manager import OAuthManager
from src.util.config import MQTT_BROKER, MQTT_PORT, HOST, PORT, SECRET_KEY
from src.util.extensions import socketio, mqtt, oauth
from src.api.auth_route import auth_blueprint


app = Flask(__name__)

CORS(app)
app.config['SECRET_KEY'] = SECRET_KEY
app.config['MQTT_BROKER_URL'] = MQTT_BROKER
app.config['MQTT_BROKER_PORT'] = MQTT_PORT
app.config['MQTT_USERNAME'] = ''
app.config['MQTT_PASSWORD'] = ''
app.config['MQTT_REFRESH_TIME'] = 1.0
app.config['MQTT_TLS_ENABLED'] = False

oauth_manager = OAuthManager(app)
app.oauth_manager = oauth_manager

app.register_blueprint(auth_blueprint)

# Bind socketio to the app
socketio.init_app(app)
mqtt.init_app(app)

mqtt.subscribe('register')

# Run the app
if __name__ == '__main__':
    socketio.run(app, host=HOST, port=PORT, use_reloader=False, debug=True)
