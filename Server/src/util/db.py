"""
Module responsible for setting up connections to MongoDB and Redis.

This module establishes connections to MongoDB and Redis, ensuring the availability of both services.

### Constants:
1. **USER_COLLECTION** - The name of the collection storing user data in MongoDB.
2. **CONTROLLER_COLLECTION** - The name of the collection storing controller data in MongoDB.

### MongoDB Schema:
1. **users** Collection:
    - **_id**: ObjectId (unique identifier for each user).
    - **email**: String (user's email address).
    - **password**: String (encrypted password for the user).
    - **controllers**: List of Strings (list of controller IDs associated with the user).

2. **controllers** Collection:
    - **_id**: ObjectId (unique identifier for each controller).
    - **name**: String (name of the controller).
    - **record**: List of Objects (records associated with irrigation events).
    - **water_used_month**: List of Objects (records for water usage by month).

### Redis Schema:
- Redis stores a list of users associated with each controller, indexed by `controller_id`:
    - **controller_id**: String (the unique identifier for each controller).
    - **user_list**: List of Dictionaries:
        - **user_id**: String (unique identifier of the user).
        - **socket_id**: String (socket ID associated with the user connection).

"""

import redis
import pymongo
from src.util.config import MONGO_URI, MONGO_DB, REDIS_HOST, REDIS_PORT

try:
    mongo_client = pymongo.MongoClient(MONGO_URI)
    mongo_db = mongo_client[MONGO_DB]
except Exception as e:
    print(f"Error connecting to MongoDB: {e}")
    exit(1)

USER_COLLECTION = 'users'
CONTROLLER_COLLECTION = 'controllers'

try:
    r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)
    r.ping()
except redis.ConnectionError as e:
    print(f"Error connecting to Redis: {e}")
    exit(1)
