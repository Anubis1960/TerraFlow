from http import HTTPStatus

from flask import Blueprint, request, jsonify

from src.service.user_service import handle_get_user_devices, handle_add_device, handle_delete_device
from src.utils.tokenizer import decode_token

user_blueprint = Blueprint('user', __name__, url_prefix='/user')


@user_blueprint.route('/devices', methods=['GET'])
def get_devices():
    token = request.headers.get('Authorization')
    token = token.split(" ")[1] if token else None
    payload = decode_token(token)
    print(payload)
    if 'error' in payload:
        return jsonify({"error": payload['error']}), HTTPStatus.UNAUTHORIZED
    if 'user_id' not in payload:
        return jsonify({"error": "Invalid token"}), HTTPStatus.UNAUTHORIZED
    user_id = payload['user_id']
    devices = handle_get_user_devices(user_id)
    print(devices)
    if not devices:
        return jsonify({"error": "User not found"}), HTTPStatus.NOT_FOUND
    return jsonify(devices), HTTPStatus.OK


@user_blueprint.route('/', methods=['PATCH'])
def add_device():
    data = request.get_json()
    print(data)
    print(request.headers)
    if not data:
        return jsonify({"error": "Invalid input"}), HTTPStatus.BAD_REQUEST
    if 'device_id' not in data:
        return jsonify({"error": "Missing required fields"}), HTTPStatus.BAD_REQUEST
    device_id = data['device_id']
    token = request.headers.get('Authorization')
    token = token.split(" ")[1] if token else None
    print(token)
    payload = decode_token(token)
    print(payload)
    if 'error' in payload:
        return jsonify({"error": payload['error']}), HTTPStatus.UNAUTHORIZED
    if 'user_id' not in payload:
        return jsonify({"error": "Invalid token"}), HTTPStatus.UNAUTHORIZED
    user_id = payload['user_id']

    added = handle_add_device(device_id, user_id)

    if not added:
        return jsonify({"error": "Failed to add device"}), HTTPStatus.NOT_FOUND

    return jsonify({"device_id": device_id}), HTTPStatus.CREATED


@user_blueprint.route('/devices/<device_id>', methods=['DELETE'])
def delete_device(device_id):
    token = request.headers.get('Authorization')
    token = token.split(" ")[1] if token else None
    payload = decode_token(token)
    if 'error' in payload:
        return jsonify({"error": payload['error']}), HTTPStatus.UNAUTHORIZED
    if 'user_id' not in payload:
        return jsonify({"error": "Invalid token"}), HTTPStatus.UNAUTHORIZED
    user_id = payload['user_id']

    deleted = handle_delete_device(device_id, user_id)

    if not deleted:
        return jsonify({"error": "Failed to delete device"}), HTTPStatus.NOT_FOUND

    return jsonify({"device_id": device_id}), HTTPStatus.OK
