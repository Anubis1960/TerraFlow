from flask import request
from src.service.socket_service import (
    handle_connect, handle_disconnect, handle_irrigate, handle_irrigation_type,
    handle_schedule_irrigation, remap_redis, handle_export,
)
from src.config.protocol import socketio
from src.utils.tokenizer import decode_token


@socketio.on('connect')
def connet_event() -> None:
    """
    Handles client connection.
    """
    print('Client connected')
    print('Request:', request)
    socket_id = request.sid
    print('Socket ID:', socket_id)
    handle_connect(socket_id)


@socketio.on('init')
def init_event(data: dict) -> None:
    """
    Initializes the client session by remapping Redis with devices.
    """
    print('Init:', data)
    socket_id = request.sid
    print("\n\n SOCKET ID:", socket_id, "\n\n")
    if 'token' not in data or 'devices' not in data:
        print('User ID not found, found:', data)
        return
    if not data['devices']:
        print('No devices found, found:', data)
        return
    token = data['token']
    payload = decode_token(token)
    if 'error' in payload:
        print('Invalid token:', payload)
        return
    user_id = payload['user_id']
    for device in data['devices']:
        remap_redis(device, user_id, socket_id)


@socketio.on('disconnect')
def disconnect_event(data: dict) -> None:
    """
    Handles client disconnection.
    """
    print('Client disconnected')
    handle_disconnect(data)


@socketio.on('trigger_irrigation')
def irrigate_event(data: dict) -> None:
    """
    Triggers manual irrigation for a device.
    """
    if 'device_id' not in data:
        print('device ID not found, found:', data)
        return
    device_id = data['device_id']
    print('Irrigating:', device_id)
    handle_irrigate(device_id)


@socketio.on('export')
def export_event(data: dict) -> None:
    """
    Handles export requests for device data.
    """
    if 'device_id' not in data:
        print('device ID or type not found, found:', data)
        return
    device_id = data['device_id']
    socket_id = request.sid
    print('Exporting:', device_id)
    handle_export(device_id, socket_id)


@socketio.on('schedule_irrigation')
def schedule_irrigation_event(data: dict) -> None:
    """
    Schedules irrigation for a device.

    :param data: dict: JSON payload with keys 'device_id', 'schedule_type', and 'schedule_time'.
    """
    if 'device_id' not in data or 'schedule_type' not in data or 'schedule_time' not in data:
        print('device ID or Schedule not found, found:', data)
        return
    if data['schedule_type'] not in ['DAILY', 'WEEKLY', 'MONTHLY']:
        print('Invalid schedule type, found:', data)
        return
    device_id = data['device_id']
    schedule = {
        'type': data['schedule_type'],
        'time': data['schedule_time']
    }
    print('Schedule:', schedule)
    handle_schedule_irrigation(device_id, schedule)


@socketio.on('irrigation_type')
def irrigation_type_event(data: dict) -> None:
    """
    Sets the irrigation type for a device.

    :param data: dict: JSON payload with keys 'device_id', 'irrigation_type', and optional 'schedule'.
    """
    if 'device_id' not in data or 'irrigation_type' not in data:
        print('device ID or irrigation type not found, found:', data)
        return
    device_id = data['device_id']
    irrigation_type = data['irrigation_type']
    schedule = data.get('schedule', {})
    print('Irrigation Type:', irrigation_type)
    handle_irrigation_type(device_id, irrigation_type, schedule)


@socketio.on('remove_schedule')
def remove_schedule_event(data: dict) -> None:
    """
    Removes irrigation schedule for a device.

    :param data: dict: JSON payload with key 'device_id'.
    """
    if 'device_id' not in data:
        print('device ID not found, found:', data)
        return
    device_id = data['device_id']
    print('Removing schedule for:', device_id)
    handle_schedule_irrigation(device_id, {})


@socketio.on('message')
def message_event(data: dict) -> None:
    """
    Handles general messages.

    :param data: dict: JSON payload containing the message data.
    """
    print('Message:', data)
