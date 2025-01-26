import json

from redis.exceptions import ResponseError

from src.util.db import r
from src.util.extensions import mqtt


def handle_connect(data) -> None:
    print(data)


def handle_disconnect(data) -> None:
    print(data)


def handle_irrigate(device_id: str) -> None:
    print('Device ID:', device_id)
    mqtt.publish(f'{device_id}/irrigate', '')


def handle_add_device(device_id: str, user_id: str) -> None:
    print('Device ID:', device_id)
    print('User ID:', user_id)
    try:
        if r.exists(device_id):
            user_list = json.loads(r.get(device_id))
        else:
            user_list = []

        if user_id not in user_list:
            user_list.append(user_id)
            json_data = json.dumps(user_list)
            r.set(device_id, json_data)
            print(f"Updated device users: {json_data}")
        else:
            print('User already exists')
    except ResponseError as e:
        print(f"Redis ResponseError: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")
    finally:
        # Print the current value of the key for debugging
        print(f"Final value for {device_id}: {r.get(device_id)}")


def handle_remove_device(device_id: str, user_id: str) -> None:
    print('Device ID:', device_id)
    print('User ID:', user_id)
    try:
        if r.exists(device_id):
            user_list = json.loads(r.get(device_id))
            if user_id in user_list:
                user_list.remove(user_id)
                if len(user_list) == 0:
                    r.delete(device_id)
                json_data = json.dumps(user_list)
                r.set(device_id, json_data)
                print(f"Updated device users: {json_data}")
            else:
                print('User not found')
        else:
            print('Device not found')
    except ResponseError as e:
        print(f"Redis ResponseError: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")
    finally:
        # Print the current value of the key for debugging
        print(f"Final value for {device_id}: {r.get(device_id)}")


def handle_schedule_irrigation(device_id: str, schedule: str) -> None:
    print('Device ID:', device_id)
    print('Schedule:', schedule)
    mqtt.publish(f'{device_id}/schedule', json.dumps(schedule))
