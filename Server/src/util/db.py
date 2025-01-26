import redis
import pymongo
from env import MONGO_URI, MONGO_DB, REDIS_HOST, REDIS_PORT

mongo_client = pymongo.MongoClient(MONGO_URI)
mongo_db = mongo_client[MONGO_DB]

r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)
r.ping()
