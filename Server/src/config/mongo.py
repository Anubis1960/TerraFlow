import pymongo
from src.utils.secrets import MONGO_URI, MONGO_DB

try:
    mongo_client = pymongo.MongoClient(MONGO_URI)
    mongo_db = mongo_client[MONGO_DB]
except Exception as e:
    print(f"Error connecting to MongoDB: {e}")
    exit(1)

CONTROLLER_COLLECTION = 'controllers'
USER_COLLECTION = 'users'