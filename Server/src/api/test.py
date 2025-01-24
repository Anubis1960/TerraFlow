from flask_socketio import emit
from src.util.extensions import socketio

@socketio.on('connect', namespace='/test')
def handle_connect():
    print('Client connected')
    emit('connected', {'data': 'You are connected!'})
    emit('message', {'data': 'Welcome to the server!'})

@socketio.on('disconnect', namespace='/test')
def handle_disconnect():
    print('Client disconnected')

@socketio.on('message', namespace='/test')
def handle_message(data):
    print(f'Message received: {data}')
    emit('message', {'data': f'Server response: {data}'})
