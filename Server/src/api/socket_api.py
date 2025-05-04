"""
Socket.IO Event Handlers for IoT Application

This module defines event handlers for various Socket.IO events, enabling real-time communication between the server
and connected clients. The handlers process user requests, manage devices, and handle irrigation scheduling.

### Key Features:
1. **Real-Time Connection Management**:
   - Handles client connections, disconnections, and initialization.

2. **device Management**:
   - Add, remove, and manage devices associated with users.
   - Fetch device data for real-time updates.

3. **Irrigation Control**:
   - Trigger manual irrigation or schedule automated irrigation tasks.

4. **User Authentication**:
   - Register and log in users using Socket.IO events.

5. **General Communication**:
   - Handles miscellaneous messages for debugging or additional communication.

### Dependencies:
- `Flask`: Used to manage HTTP requests (e.g., `request.sid` for socket session IDs).
- `socketio`: For handling WebSocket communication.
- Custom Services (`socket_service`):
  - Contains core logic for handling devices, irrigation, user authentication, etc.

"""

from flask import request
from src.service.socket_service import (
    handle_connect, handle_disconnect, handle_irrigate,
    handle_schedule_irrigation, remap_redis, handle_export,
)
from src.config.protocol import socketio
from src.utils.tokenizer import decode_token


@socketio.on('connect')
def connet_event() -> None:
    """
    Handles client connection.

    Actions:
        - Prints a connection message and logs the socket ID.
        - Calls `handle_connect` to process the new connection.

    Returns:
        None

    Logs:
        - "Client connected"
        - "Socket ID: <socket_id>"
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

    Args:
        data (dict): JSON containing user information and associated devices.
            Required keys: 'user_id', 'devices'.

    Returns:
        None

    Actions:
        - Remaps Redis with the user ID, devices, and the socket ID.
        - Validates presence of required keys and devices.

    Logs:
        - "Init: <data>"
        - Errors if 'user_id' or 'devices' are missing or empty.
    """
    print('Init:', data)
    socket_id = request.sid
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

    Args:
        data (dict): JSON payload (optional) sent during disconnection.

    Returns:
        None

    Actions:
        - Calls `handle_disconnect` to process the disconnection.

    Logs:
        - "Client disconnected"
    """
    print('Client disconnected')
    handle_disconnect(data)


@socketio.on('trigger_irrigation')
def irrigate_event(data: dict) -> None:
    """
    Triggers manual irrigation for a device.

    Args:
        data (dict): JSON payload with the required key 'device_id'.

    Returns:
        None

    Actions:
        - Validates presence of 'device_id' in the payload.
        - Calls `handle_irrigate` to initiate irrigation.

    Logs:
        - "Irrigating: <device_id>"
        - Errors if 'device_id' is missing.
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

    Args:
        data (dict): JSON payload with keys 'device_id' and 'type'.

    Returns:
        None

    Logs:
        - Errors if required keys are missing.
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

    Args:
        data (dict): JSON payload with keys:
            - 'device_id': ID of the device.
            - 'schedule_type': Type of schedule ('DAILY', 'WEEKLY', 'MONTHLY').
            - 'schedule_time': Time for the schedule.

    Returns:
        None

    Actions:
        - Validates required keys and schedule type.
        - Calls `handle_schedule_irrigation` with the device ID and schedule.

    Logs:
        - Errors if required keys are missing or schedule type is invalid.
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


@socketio.on('remove_schedule')
def remove_schedule_event(data: dict) -> None:
    """
    Removes irrigation schedule for a device.

    Args:
        data (dict): JSON payload with the key 'device_id'.

    Returns:
        None

    Actions:
        - Validates presence of 'device_id' in the payload.
        - Calls `handle_schedule_irrigation` with an empty schedule to remove the existing schedule.

    Logs:
        - "Removing schedule for: <device_id>"
        - Errors if 'device_id' is missing.
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

    Args:
        data (dict): JSON payload of the message.

    Returns:
        None

    Logs:
        - "Message: <data>"
    """
    print('Message:', data)