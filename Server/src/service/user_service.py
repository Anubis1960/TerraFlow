import json

from bson import ObjectId

from src.config.mongo import mongo_db, DEVICE_COLLECTION, USER_COLLECTION
from src.config.redis import r
from src.config.protocol import mqtt


def handle_get_user_devices(user_id: str):
    """
    Fetches the devices associated with a user from the database.

    :param user_id: The ID of the user whose devices are to be fetched.
    :return: A list of device IDs associated with the user.
    """
    # Check if the user exists in the database
    user = mongo_db[USER_COLLECTION].find_one({"_id": ObjectId(user_id)})
    if not user:
        return None

    # Return the list of devices associated with the user
    return user.get("devices", [])


def handle_add_device(device_id: str, user_id: str):
    """
    Adds a device to a user's account in the database.

    :param device_id: The ID of the device to be added.
    :param user_id: The ID of the user to whom the device is to be added.
    :return: True if the device was successfully added, False otherwise.
    """
    # Check if the user exists in the database
    user = mongo_db[USER_COLLECTION].find_one({"_id": ObjectId(user_id)})
    if not user:
        return False

    # Get the list of devices associated with the user
    devices = user.get("devices", [])

    print(devices)

    # Check if the device exists in the database
    new_device = mongo_db[DEVICE_COLLECTION].find_one({'_id': ObjectId(device_id)})
    if not new_device:
        print("Device not found")
        return False

    print(new_device)

    # If the device is not already associated with the user, add it
    if device_id not in devices:
        devices.append(device_id)
        mongo_db[USER_COLLECTION].update_one({"_id": ObjectId(user_id)}, {"$set": {"devices": devices}})

    #  TODO Redis

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

    return True


def handle_delete_device(device_id: str, user_id: str):
    user = mongo_db[USER_COLLECTION].find_one({"_id": ObjectId(user_id)})
    if not user:
        return False
    devices = user.get("devices", [])
    if device_id in devices:
        devices.remove(device_id)
        mongo_db[USER_COLLECTION].update_one({"_id": ObjectId(user_id)}, {"$set": {"devices": devices}})

    #  TODO Redis

    device_key = f"device:{device_id}"

    if r.exists(device_key):
        user_list = json.loads(r.get(device_key))
        if user_id in user_list:
            user_list.remove(user_id)
            r.set(device_key, json.dumps(user_list))

    return True

