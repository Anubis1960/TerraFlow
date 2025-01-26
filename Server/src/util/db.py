import redis
import pymongo

mongo_client = pymongo.MongoClient('mongodb://localhost:27017/')
mongo_db = mongo_client['iot_app']

r = redis.Redis(host='localhost', port=6379, decode_responses=True)
r.ping()
