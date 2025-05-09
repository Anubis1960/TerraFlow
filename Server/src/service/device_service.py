from bson import ObjectId

from src.config.mongo import mongo_db, DEVICE_COLLECTION


def handle_get_device_data(device_id: str):
    device = mongo_db[DEVICE_COLLECTION].find_one({"_id": ObjectId(device_id)})
    if not device:
        return None

    return {
        'record': device.get('record', []),
        'water_usage': device.get('water_usage', []),
    }
