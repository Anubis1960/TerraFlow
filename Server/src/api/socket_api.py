import json
from flask_socketio import emit
from src.util.extensions import socketio, mqtt
from src.service.socket_service import handle_connect, handle_disconnect, handle_irrigate, handle_add_device, handle_remove_device, handle_schedule_irrigation


@socketio.on('connect')
def connet_event(data):
    print('Client connected')
    handle_connect(data)


@socketio.on('disconnect')
def disconnect_event(data):
    print('Client disconnected')
    handle_disconnect(data)


@socketio.on('irrigate')
def irrigate_event(data):
    print('Irrigating')
    device_id = data['device_id']
    handle_irrigate(device_id)


@socketio.on('export')
def export_event(data):
    pass


@socketio.on('add_device')
def add_device_event(data):
    print('Adding device')
    device_id = data['device_id']
    user_id = data['user_id']
    handle_add_device(device_id, user_id)


@socketio.on('remove_device')
def remove_device_event(data):
    print('Removing device')
    device_id = data['device_id']
    user_id = data['user_id']
    handle_remove_device(device_id, user_id)


@socketio.on('schedule_irrigation')
def schedule_irrigation_event(data):
    print('Scheduling irrigation')
    device_id = data['device_id']
    schedule = data['schedule']
    handle_schedule_irrigation(device_id, schedule)
