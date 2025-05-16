import json

from bson import ObjectId

from src.config.mongo import mongo_db, DEVICE_COLLECTION
from src.config.protocol import mqtt


def handle_get_device_data(device_id: str):
    device = mongo_db[DEVICE_COLLECTION].find_one({"_id": ObjectId(device_id)})
    if not device:
        return None

    return {
        'record': device.get('record', []),
        'water_usage': device.get('water_usage', []),
    }


def handle_update_watering_type(device_id: str, json_data: dict):
    mqtt.publish(f'{device_id}/watering_type', json.dumps(json_data))

    return {
        'message': 'Watering type updated successfully',
    }
