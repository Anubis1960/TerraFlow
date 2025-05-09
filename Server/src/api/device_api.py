from http import HTTPStatus

from flask import Blueprint, jsonify, request

from src.service.device_service import handle_get_device_data
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
