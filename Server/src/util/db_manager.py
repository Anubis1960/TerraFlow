import pymongo
from bson import ObjectId

from src.util.config import MONGO_URI, MONGO_DB
from src.util.db import CONTROLLER_COLLECTION

try:
    mongo_client = pymongo.MongoClient(MONGO_URI)
    mongo_db = mongo_client[MONGO_DB]

    controller = mongo_db[CONTROLLER_COLLECTION].find_one({"_id": ObjectId("d372fd8aa13bc0dc8e891b20")})

    sensor_data = []
    for record in controller['record']:
        if not record['timestamp'].startswith('2021'):
            sensor_data.append(record)

    print(sensor_data)
    mongo_db[CONTROLLER_COLLECTION].update_one(
        {"_id": ObjectId("d372fd8aa13bc0dc8e891b20")},
        {"$set": {"record": sensor_data}}
    )

except Exception as e:
    print(f"Error connecting to MongoDB: {e}")
    exit(1)
