from http import HTTPStatus
from flask import Blueprint, request, jsonify
from src.service.user_service import (handle_get_user_devices, handle_add_device, handle_delete_device,
                                      handle_predict_disease)
from src.utils.tokenizer import decode_token
user_blueprint = Blueprint('user', __name__, url_prefix='/user')


@user_blueprint.route('/devices', methods=['GET'])
def get_devices():
    """
    Endpoint to get all devices associated with a user.
    The user must be authenticated via a token in the Authorization header.
    """
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
    """
    Endpoint to add a device to a user's account.
    The request should contain a JSON body with the device_id field.
    The user must be authenticated via a token in the Authorization header.
    """
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

    res = handle_add_device(device_id, user_id)

    if "error" in res:
        return jsonify({"error": res['error']}), HTTPStatus.NOT_FOUND

    if not res:
        return jsonify({"error": "Failed to add device"}), HTTPStatus.NOT_FOUND

    return jsonify(res), HTTPStatus.CREATED


@user_blueprint.route('/devices/<device_id>', methods=['DELETE'])
def delete_device(device_id):
    """
    Endpoint to delete a device from a user's account.
    The user must be authenticated via a token in the Authorization header.
    :param device_id: The ID of the device to be deleted.
    """
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


@user_blueprint.route('/predict-disease', methods=['POST'])
def predict_disease():
    """
    Endpoint to predict disease from an image.
    The image should be sent as a file in the request.
    """
    if 'image' not in request.files:
        return jsonify({"error": "No image file provided"}), HTTPStatus.BAD_REQUEST

    image_file = request.files['image']
    if not image_file:
        return jsonify({"error": "Invalid image file"}), HTTPStatus.BAD_REQUEST

    try:
        prediction = handle_predict_disease(image_file)
        return jsonify(prediction), HTTPStatus.OK
    except Exception as e:
        print(f"Error during prediction: {e}")
        return jsonify({"error": str(e)}), HTTPStatus.INTERNAL_SERVER_ERROR
