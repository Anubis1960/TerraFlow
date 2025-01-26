from src.service.socket_service import handle_connect, handle_disconnect, handle_irrigate, handle_add_device, \
    handle_remove_device, handle_schedule_irrigation
from src.util.extensions import socketio


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
    if 'device_id' not in data:
        print('Device ID not found, found:', data)
        return
    device_id = data['device_id']
    handle_irrigate(device_id)


@socketio.on('export')
def export_event(data):
    socketio.emit('message', data, room=data['user_id'])


@socketio.on('add_device')
def add_device_event(data):
    print('Adding device')
    if 'device_id' not in data or 'user_id' not in data:
        print('Device ID or User ID not found, found:', data)
        return
    device_id = data['device_id']
    user_id = data['user_id']
    handle_add_device(device_id, user_id)


@socketio.on('remove_device')
def remove_device_event(data):
    print('Removing device')
    if 'device_id' not in data or 'user_id' not in data:
        print('Device ID or User ID not found, found:', data)
        return
    device_id = data['device_id']
    user_id = data['user_id']
    handle_remove_device(device_id, user_id)


@socketio.on('schedule_irrigation')
def schedule_irrigation_event(data):
    print('Scheduling irrigation')
    if 'device_id' not in data or 'schedule' not in data:
        print('Device ID or Schedule not found, found:', data)
        return
    device_id = data['device_id']
    schedule = data['schedule']
    handle_schedule_irrigation(device_id, schedule)


@socketio.on('message')
def message_event(data):
    print('Message:', data)


@socketio.on('register')
def register_event(data):
    print('Registering')
    print('Data:', data)


@socketio.on('login')
def login_event(data):
    print('Logging in')
    print('Data:', data)
