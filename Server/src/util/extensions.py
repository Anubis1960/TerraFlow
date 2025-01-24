from flask_socketio import SocketIO

# Initialize socketio (but don't bind it to the app yet)
socketio = SocketIO(cors_allowed_origins='*', logger=True, engineio_logger=True)