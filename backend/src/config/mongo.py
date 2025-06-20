import pymongo
from pymongoose.methods import set_schemas

from src.model.device_model import Device
from src.model.user_model import User
from src.utils.secrets import MONGO_URI, MONGO_DB

try:
    mongo_client = pymongo.MongoClient(MONGO_URI)
    mongo_db = mongo_client[MONGO_DB]
    schemas = {
        'users': User,
        'devices': Device
    }
    set_schemas(mongo_db, schemas)

except Exception as e:
    print(f"Error connecting to MongoDB: {e}")
    exit(1)

DEVICE_COLLECTION = 'devices'
USER_COLLECTION = 'users'
