import json

from redis import ResponseError

from src.util.db import r
from src.util.extensions import socketio, mqtt


def extract_device_id(topic: str) -> str:
    return topic.split('/')[0]


def register_device(payload: str) -> None:
    json_data = json.loads(payload)
    print('JSON data:', json_data)
    device_id = json_data['device_id']
    mqtt.subscribe(f'{device_id}/record')
    mqtt.subscribe(f'{device_id}/predict')


def predict(payload: str, topic: str) -> None:
    json_data = json.loads(payload)
    device_id = extract_device_id(topic)
    print('JSON data:', json_data)
    print('Device ID:', device_id)


def record(payload: str, topic: str) -> None:
    json_data = json.loads(payload)
    device_id = extract_device_id(topic)
    print('JSON data:', json_data)
    print('Device ID:', device_id)
    try:
        if r.exists(device_id):
            user_list = json.loads(r.get(device_id))
        else:
            user_list = []
        for user_id in user_list:
            socketio.emit('record', json_data, room=user_id)

    except ResponseError as e:
        print(f"Redis ResponseError: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")
    finally:
        # Print the current value of the key for debugging
        print(f"Final value for {device_id}: {r.get(device_id)}")
