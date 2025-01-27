from src.service.socket_service import handle_connect, handle_disconnect, handle_irrigate, handle_add_device, \
    handle_remove_device, handle_schedule_irrigation, handle_register, handle_login
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
    if 'device_id' not in data:
        print('Device ID not found, found:', data)
        return
    device_id = data['device_id']
    handle_irrigate(device_id)


@socketio.on('export')
def export_event(data):
    if 'device_id' not in data or 'type' not in data:
        print('Device ID or type not found, found:', data)
        return


@socketio.on('add_device')
def add_device_event(data):
    if 'device_id' not in data or 'user_id' not in data or 'socket_id' not in data:
        print('Device ID or User ID not found, found:', data)
        return
    device_id = data['device_id']
    user_id = data['user_id']
    socket_id = data['socket_id']
    handle_add_device(device_id, user_id, socket_id)


@socketio.on('remove_device')
def remove_device_event(data):
    if 'device_id' not in data or 'user_id' not in data:
        print('Device ID or User ID not found, found:', data)
        return
    device_id = data['device_id']
    user_id = data['user_id']
    handle_remove_device(device_id, user_id)


@socketio.on('schedule_irrigation')
def schedule_irrigation_event(data):
    if 'device_id' not in data or 'schedule_type' not in data or 'schedule_time' not in data:
        print('Device ID or Schedule not found, found:', data)
        return
    if data['schedule_type'] not in ['DAILY', 'WEEKLY']:
        print('Invalid schedule type, found:', data)
        return
    device_id = data['device_id']
    schedule = {
        'type': data['schedule_type'],
        'time': data['schedule_time']
    }
    handle_schedule_irrigation(device_id, schedule)


@socketio.on('message')
def message_event(data):
    print('Message:', data)


@socketio.on('register')
def register_event(data):
    if 'email' not in data or 'password' not in data:
        print('Email or Password not found, found:', data)
        return
    email = data['email']
    password = data['password']
    user = handle_register(email, password)
    socketio.emit('register', user)


@socketio.on('login')
def login_event(data):
    if 'email' not in data or 'password' not in data:
        print('Email or Password not found, found:', data)
        return
    email = data['email']
    password = data['password']
    user = handle_login(email, password)
    socketio.emit('login', user)
