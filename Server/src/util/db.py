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

if __name__ == '__main__':
    print("Connected to Redis and MongoDB")
    
    # Print collections in MongoDB
    print("Collections in MongoDB:")
    for collection in mongo_db.list_collection_names():
        print(collection)

    # Fetch and print the controllers collection
    controllers = mongo_db.controllers.find()  # Make sure it's 'controller' and not 'controllers'

    print("Controllers in MongoDB:")
    
    # Convert cursor to list
    controllers = list(controllers)

    if not controllers:
        print("No controllers found in the database.")
    
    for controller in controllers:
        print("Controller:")
        print(controller)
        # mongo_db.controller.delete_one({'_id': controller['_id']})
