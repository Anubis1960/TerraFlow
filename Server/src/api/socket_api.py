"""
Socket.IO Event Handlers for IoT Application

This module defines event handlers for various Socket.IO events, enabling real-time communication between the server
and connected clients. The handlers process user requests, manage controllers, and handle irrigation scheduling.

### Key Features:
1. **Real-Time Connection Management**:
   - Handles client connections, disconnections, and initialization.

2. **Controller Management**:
   - Add, remove, and manage controllers associated with users.
   - Fetch controller data for real-time updates.

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
  - Contains core logic for handling controllers, irrigation, user authentication, etc.

"""

from flask import request
from src.service.socket_service import (
    handle_connect, handle_disconnect, handle_irrigate, handle_add_controller,
    handle_remove_controller, handle_schedule_irrigation, handle_retrieve_controller_data, remap_redis, handle_export,
    handle_logout, handle_fetch_controllers
)
from src.util.extensions import socketio
from src.util.tokenizer import decode_token


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
    Initializes the client session by remapping Redis with controllers.

    Args:
        data (dict): JSON containing user information and associated controllers.
            Required keys: 'user_id', 'controllers'.

    Returns:
        None

    Actions:
        - Remaps Redis with the user ID, controllers, and the socket ID.
        - Validates presence of required keys and controllers.

    Logs:
        - "Init: <data>"
        - Errors if 'user_id' or 'controllers' are missing or empty.
    """
    print('Init:', data)
    socket_id = request.sid
    if 'token' not in data or 'controllers' not in data:
        print('User ID not found, found:', data)
        return
    if not data['controllers']:
        print('No controllers found, found:', data)
        return
    token = data['token']
    payload = decode_token(token)
    if 'error' in payload:
        print('Invalid token:', payload)
        return
    user_id = payload['user_id']
    for controller in data['controllers']:
        remap_redis(controller, user_id, socket_id)


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
    Triggers manual irrigation for a controller.

    Args:
        data (dict): JSON payload with the required key 'controller_id'.

    Returns:
        None

    Actions:
        - Validates presence of 'controller_id' in the payload.
        - Calls `handle_irrigate` to initiate irrigation.

    Logs:
        - "Irrigating: <controller_id>"
        - Errors if 'controller_id' is missing.
    """
    if 'controller_id' not in data:
        print('controller ID not found, found:', data)
        return
    controller_id = data['controller_id']
    print('Irrigating:', controller_id)
    handle_irrigate(controller_id)


@socketio.on('export')
def export_event(data: dict) -> None:
    """
    Handles export requests for controller data.

    Args:
        data (dict): JSON payload with keys 'controller_id' and 'type'.

    Returns:
        None

    Logs:
        - Errors if required keys are missing.
    """
    if 'controller_id' not in data:
        print('controller ID or type not found, found:', data)
        return
    controller_id = data['controller_id']
    socket_id = request.sid
    print('Exporting:', controller_id)
    handle_export(controller_id, socket_id)


@socketio.on('add_controller')
def add_controller_event(data: dict) -> None:
    """
    Adds a controller for a user.

    Args:
        data (dict): JSON payload with keys 'controller_id' and 'user_id'.

    Returns:
        None

    Actions:
        - Calls `handle_add_controller` with the controller ID, user ID, and socket ID.

    Logs:
        - Errors if required keys are missing.
    """
    if 'controller_id' not in data or 'token' not in data:
        print('controller ID or User ID not found, found:', data)
        return
    controller_id = data['controller_id']
    token = data['token']
    payload = decode_token(token)
    if 'error' in payload:
        print('Invalid token:', payload)
        return
    user_id = payload['user_id']
    socket_id = request.sid

    if len(controller_id) != 24:
        print(f"Invalid controller ID: {controller_id}")
        socketio.emit('error', {'error_msg': f"Invalid controller ID: {controller_id}"}, room=socket_id)

    handle_add_controller(controller_id, user_id, socket_id)


@socketio.on('remove_controller')
def remove_controller_event(data: dict) -> None:
    """
    Removes a controller for a user.

    Args:
        data (dict): JSON payload with keys 'controller_id' and 'token'.

    Returns:
        None

    Actions:
        - Calls `handle_remove_controller` to remove the controller for the given user.

    Logs:
        - Errors if required keys are missing.
    """
    if 'controller_id' not in data or 'token' not in data:
        print('controller ID or User ID not found, found:', data)
        return
    controller_id = data['controller_id']
    token = data['token']
    payload = decode_token(token)
    if 'error' in payload:
        print('Invalid token:', payload)
        return
    user_id = payload['user_id']
    socket_id = request.sid
    handle_remove_controller(controller_id, user_id, socket_id)


@socketio.on('schedule_irrigation')
def schedule_irrigation_event(data: dict) -> None:
    """
    Schedules irrigation for a controller.

    Args:
        data (dict): JSON payload with keys:
            - 'controller_id': ID of the controller.
            - 'schedule_type': Type of schedule ('DAILY', 'WEEKLY', 'MONTHLY').
            - 'schedule_time': Time for the schedule.

    Returns:
        None

    Actions:
        - Validates required keys and schedule type.
        - Calls `handle_schedule_irrigation` with the controller ID and schedule.

    Logs:
        - Errors if required keys are missing or schedule type is invalid.
    """
    if 'controller_id' not in data or 'schedule_type' not in data or 'schedule_time' not in data:
        print('controller ID or Schedule not found, found:', data)
        return
    if data['schedule_type'] not in ['DAILY', 'WEEKLY', 'MONTHLY']:
        print('Invalid schedule type, found:', data)
        return
    controller_id = data['controller_id']
    schedule = {
        'type': data['schedule_type'],
        'time': data['schedule_time']
    }
    print('Schedule:', schedule)
    handle_schedule_irrigation(controller_id, schedule)


@socketio.on('remove_schedule')
def remove_schedule_event(data: dict) -> None:
    """
    Removes irrigation schedule for a controller.

    Args:
        data (dict): JSON payload with the key 'controller_id'.

    Returns:
        None

    Actions:
        - Validates presence of 'controller_id' in the payload.
        - Calls `handle_schedule_irrigation` with an empty schedule to remove the existing schedule.

    Logs:
        - "Removing schedule for: <controller_id>"
        - Errors if 'controller_id' is missing.
    """
    if 'controller_id' not in data:
        print('controller ID not found, found:', data)
        return
    controller_id = data['controller_id']
    print('Removing schedule for:', controller_id)
    handle_schedule_irrigation(controller_id, {})


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


@socketio.on('fetch_controller_data')
def retrieve_controller_data_event(data: dict) -> None:
    """
    Fetches data for a specific controller.

    Args:
        data (dict): JSON payload with the key 'controller_id'.

    Actions:
        - Calls `handle_retrieve_controller_data` to fetch controller data.

    Logs:
        - Errors if 'controller_id' is missing.
    """
    print('Retrieving controller data:', data)
    if 'controller_id' not in data:
        print('controller ID not found, found:', data)
        return
    controller_id = data['controller_id']
    socket_id = request.sid
    handle_retrieve_controller_data(controller_id, socket_id)


@socketio.on('fetch_controllers')
def fetch_controllers_event(data: dict) -> None:
    """
    Fetches controllers associated with a user.

    Args:
        data (dict): JSON payload with the key
            - 'token': User authentication token.

    Actions:
        - Calls
        - Calls `handle_fetch_controllers` to fetch controller data.

    Logs:
        - Errors if 'token' is missing.

    Returns:
        None
    """
    print('Fetching controllers:', data)

    if 'token' not in data:
        print('Token not found, found:', data)
        return
    token = data['token']
    payload = decode_token(token)
    if 'error' in payload:
        print('Invalid token:', payload)
        return
    user_id = payload['user_id']
    socket_id = request.sid
    handle_fetch_controllers(user_id, socket_id)


@socketio.on('logout')
def logout(data: dict) -> None:
    """
    Handles user logout requests.

    Returns:
        None

    """
    print('Logging out:', data)
    if 'token' in data and 'controllerIds' in data:
        token = data['token']
        controller_ids = data['controllerIds']
        decoded_token = decode_token(token)
        if 'error' in decoded_token:
            return
        user_id = decoded_token['user_id']
        handle_logout(user_id, controller_ids)
