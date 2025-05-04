from http import HTTPStatus

from flask import Blueprint, jsonify

from src.service.device_service import handle_get_device_data

device_blueprint = Blueprint('device', __name__, url_prefix='/device')


@device_blueprint.route('/<device_id>/data', methods=['GET'])
def get_device_data(device_id):
    device = handle_get_device_data(device_id)
    print(device)
    if not device:
        return jsonify({"error": "Device not found"}), HTTPStatus.NOT_FOUND
    return jsonify(device), HTTPStatus.OK
