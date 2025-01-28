from flask import request

from src.service.socket_service import (handle_connect, handle_disconnect, handle_irrigate, handle_add_controller,
                                        handle_remove_controller, handle_schedule_irrigation, handle_register,
                                        handle_login,
                                        handle_retrieve_controller_data, initialise_redis)
from src.util.extensions import socketio


@socketio.on('connect')
def connet_event(data):
    print('Client connected')
    socket_id = request.sid
    print('Socket ID:', socket_id)
    if data is not None:
        print('Data:', data)
        user_id = data['user_id']
        controllers = data['controllers']
        initialise_redis(controllers, socket_id, user_id)
    handle_connect(socket_id)


@socketio.on('disconnect')
def disconnect_event(data):
    print('Client disconnected')
    handle_disconnect(data)


@socketio.on('irrigate')
def irrigate_event(data):
    if 'controller_id' not in data:
        print('controller ID not found, found:', data)
        return
    controller_id = data['controller_id']
    handle_irrigate(controller_id)


@socketio.on('export')
def export_event(data):
    if 'controller_id' not in data or 'type' not in data:
        print('controller ID or type not found, found:', data)
        return


@socketio.on('add_controller')
def add_controller_event(data):
    if 'controller_id' not in data or 'user_id' not in data:
        print('controller ID or User ID not found, found:', data)
        return
    controller_id = data['controller_id']
    user_id = data['user_id']
    socket_id = request.sid
    handle_add_controller(controller_id, user_id, socket_id)


@socketio.on('remove_controller')
def remove_controller_event(data):
    if 'controller_id' not in data or 'user_id' not in data:
        print('controller ID or User ID not found, found:', data)
        return
    controller_id = data['controller_id']
    user_id = data['user_id']
    socket_id = request.sid
    handle_remove_controller(controller_id, user_id, socket_id)


@socketio.on('schedule_irrigation')
def schedule_irrigation_event(data):
    if 'controller_id' not in data or 'schedule_type' not in data or 'schedule_time' not in data:
        print('controller ID or Schedule not found, found:', data)
        return
    if data['schedule_type'] not in ['DAILY', 'WEEKLY']:
        print('Invalid schedule type, found:', data)
        return
    controller_id = data['controller_id']
    schedule = {
        'type': data['schedule_type'],
        'time': data['schedule_time']
    }
    handle_schedule_irrigation(controller_id, schedule)


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
    socket_id = request.sid
    user = handle_register(email, password)
    socketio.emit('register_response', user, room=socket_id)


@socketio.on('login')
def login_event(data):
    if 'email' not in data or 'password' not in data:
        print('Email or Password not found, found:', data)
        return
    email = data['email']
    password = data['password']
    socket_id = request.sid
    user = handle_login(email, password)
    print('User:', user)
    socketio.emit('login_response', user, room=socket_id)


@socketio.on('fetch_controller_data')
def retrieve_controller_data_event(data):
    print('Retrieving controller data:', data)
    if 'controller_id' not in data:
        print('controller ID not found, found:', data)
        return
    controller_id = data['controller_id']
    socket_id = request.sid
    handle_retrieve_controller_data(controller_id, socket_id)
