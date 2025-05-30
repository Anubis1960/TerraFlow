import json

import numpy as np
from bson import ObjectId

from src.config.mongo import mongo_db, DEVICE_COLLECTION, USER_COLLECTION
from src.config.redis import r
from src.utils.predict import predict_disease
import cv2


def handle_get_user_devices(user_id: str):
    """
    Fetches the devices associated with a user from the database.

    :param user_id: The ID of the user whose devices are to be fetched.
    :return: A list of device IDs associated with the user.
    """
    # Check if the user exists in the database
    user = mongo_db[USER_COLLECTION].find_one({"_id": ObjectId(user_id)})
    print(user)
    if not user:
        return None
    devices = user.get("devices", []) if user else []
    res = []
    for device_id in devices:
        device = mongo_db[DEVICE_COLLECTION].find_one({"_id": ObjectId(device_id)})
        if device:
            res.append({
                "id": str(device["_id"]),
                "name": device.get("name", ""),
            })

    # Return the list of devices associated with the user
    return res


def handle_add_device(device_id: str, user_id: str) -> dict:
    """
    Adds a device to a user's account in the database.

    :param device_id: The ID of the device to be added.
    :param user_id: The ID of the user to whom the device is to be added.
    :return: True if the device was successfully added, False otherwise.
    """
    # Check if the user exists in the database
    user = mongo_db[USER_COLLECTION].find_one({"_id": ObjectId(user_id)})
    if not user:
        return {"error": "User not found"}

    # Get the list of devices associated with the user
    devices = user.get("devices", [])

    print(devices)

    # Check if the device exists in the database
    new_device = mongo_db[DEVICE_COLLECTION].find_one({'_id': ObjectId(device_id)})
    if not new_device:
        print("Device not found")
        return {"error": "Device not found"}

    print(new_device)

    # If the device is not already associated with the user, add it
    if device_id not in devices:
        devices.append(device_id)
        mongo_db[USER_COLLECTION].update_one({"_id": ObjectId(user_id)}, {"$set": {"devices": devices}})

    device_key = f"device:{device_id}"

    # Check if the device is already in Redis
    if r.exists(device_key):
        user_list = json.loads(r.get(device_key))
    else:
        user_list = []

    if user_id not in user_list:
        user_list.append(user_id)
        r.set(device_key, json.dumps(user_list))

    print(user_list)

    return {"id": device_id, "name": new_device.get("name", "")}


def handle_delete_device(device_id: str, user_id: str):
    user = mongo_db[USER_COLLECTION].find_one({"_id": ObjectId(user_id)})
    if not user:
        return False
    devices = user.get("devices", [])
    if device_id in devices:
        devices.remove(device_id)
        mongo_db[USER_COLLECTION].update_one({"_id": ObjectId(user_id)}, {"$set": {"devices": devices}})

    device_key = f"device:{device_id}"

    if r.exists(device_key):
        user_list = json.loads(r.get(device_key))
        if user_id in user_list:
            user_list.remove(user_id)
            r.set(device_key, json.dumps(user_list))

    return True


def handle_predict_disease(image_file) -> dict[str, str]:
    """
    Predicts disease from an image file.

    :param image_file: The path to the image file.
    :return: A dictionary containing the prediction result.
    """
    file_bytes = image_file.read()
    np_arr = np.frombuffer(file_bytes, np.uint8)
    image = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    if image is None:
        return {"error": "Invalid image file"}
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)  # Convert BGR to RGB
    prediction = predict_disease(image)
    return prediction
