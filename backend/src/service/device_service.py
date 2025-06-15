import json

from bson import ObjectId

from src.config.mongo import mongo_db, DEVICE_COLLECTION
from src.config.protocol import mqtt


def handle_get_device_data(device_id: str) -> dict or None:
    """
    fetches the irrigation data for a specific device.

    :param device_id: str: The ID of the device whose data is to be fetched.
    :return: dict or None: A dictionary containing the device's irrigation record and water usage data.
    """
    device = mongo_db[DEVICE_COLLECTION].find_one({"_id": ObjectId(device_id)})
    print(f"Fetching data for device: {device_id}")
    if not device:
        return None

    return {
        'record': device.get('record', []),
        'water_usage': device.get('water_usage', []),
    }


def handle_update_watering_type(device_id: str, json_data: dict) -> dict:
    """
    Updates the watering type for a specific device and publishes the change to MQTT.

    :param device_id: str: The ID of the device whose watering type is to be updated.
    :param json_data: str: A dictionary containing the new watering type and schedule if applicable.
    :return: dict: A dictionary indicating the success of the operation.
    """
    mqtt.publish(f'{device_id}/watering_type', json.dumps(json_data))

    return {
        'message': 'Watering type updated successfully',
    }


def handle_update_device(device_id: str, device_name: str) -> dict:
    """
    updates the name of a device in the database.

    :param device_id: str: The ID of the device to be updated.
    :param device_name: str: The new name for the device.
    :return: dict A dictionary indicating the success of the operation or an error message.
    """
    result = mongo_db[DEVICE_COLLECTION].update_one(
        {"_id": ObjectId(device_id)},
        {"$set": {"name": device_name}}
    )

    if result.modified_count == 0:
        return {"error": "Device not found or name is the same"}

    return {"message": f"Device {device_id} updated to {device_name}"}
