import redis
from src.utils.secrets import REDIS_HOST, REDIS_PORT

try:
    r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)
    r.ping()
except redis.ConnectionError as e:
    print(f"Error connecting to Redis: {e}")
    exit(1)