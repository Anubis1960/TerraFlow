from http import HTTPStatus

from flask import Blueprint, jsonify, request

from src.service.device_service import handle_get_device_data, handle_update_watering_type
from src.service.user_service import handle_get_user_devices
from src.utils.tokenizer import decode_token

device_blueprint = Blueprint('device', __name__, url_prefix='/device')


@device_blueprint.route('/<device_id>/data', methods=['GET'])
def get_device_data(device_id):
    token = request.headers.get('Authorization')
    token = token.split(" ")[1] if token else None
    payload = decode_token(token)
    if 'error' in payload:
        return jsonify({"error": payload['error']}), HTTPStatus.UNAUTHORIZED
    if 'user_id' not in payload:
        return jsonify({"error": "Invalid token"}), HTTPStatus.UNAUTHORIZED
    user_id = payload['user_id']
    user_devices = handle_get_user_devices(user_id)
    if device_id not in user_devices:
        return jsonify({"error": "Device not found"}), HTTPStatus.NOT_FOUND
    device = handle_get_device_data(device_id)

    if not device:
        return jsonify({"error": "Device not found"}), HTTPStatus.NOT_FOUND
    return jsonify(device), HTTPStatus.OK


@device_blueprint.route('/<device_id>/watering_type', methods=['PUT'])
def update_watering_type(device_id):
    data = request.get_json()
    if not data or 'watering_type' not in data:
        return jsonify({"error": "Invalid input"}), HTTPStatus.BAD_REQUEST
    watering_type = data['watering_type']
    json_data = {
        'watering_type': watering_type,
        "schedule": data.get('schedule', None),
    }
    msg = handle_update_watering_type(device_id, json_data)

    if 'error' in msg:
        return jsonify(msg), HTTPStatus.BAD_REQUEST
    return jsonify(msg), HTTPStatus.OK