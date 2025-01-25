import json
from flask_socketio import emit
from src.util.extensions import socketio, mqtt
import typing
import paho.mqtt.client
import datetime


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
