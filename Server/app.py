import os
from flask import Flask
from src.util.extensions import socketio
import logging
import src.api.test

# Flask app initialization
app = Flask(__name__)
app.config['SECRET_KEY'] = os.urandom(24)

# Bind socketio to the app
socketio.init_app(app)

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)


# Run the app
if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
