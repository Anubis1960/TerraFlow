import typing
import paho.mqtt.client
from src.service.mqtt_service import register_device, predict, record_sensor_data, record_water_used
from src.util.extensions import mqtt


@mqtt.on_connect()
def handle_connect(client: paho.mqtt.client.Client, userdata: typing.Any, flags: dict, rc: int):
    print(f"Connected with result code {rc}, client: {client}")


@mqtt.on_message()
def handle_mqtt_message(client: paho.mqtt.client.Client, userdata: typing.Any, message: paho.mqtt.client.MQTTMessage):
    try:
        print(f"Received message '{message.payload.decode()}' on topic '{message.topic}' with QoS {message.qos}")
        topic = message.topic
        payload = message.payload.decode()
    except Exception as e:
        print(f"Error: {e}")
        return

    if topic.endswith('/record/sensor_data'):
        print('Recording')
        record_sensor_data(payload, topic)
    elif topic.endswith('/predict'):
        print('Predicting')
        predict(payload, topic)
    elif topic.endswith('/record/water_used'):
        print('Water used')
        record_water_used(payload, topic)
    elif topic == 'register':
        print('Registering')
        register_device(payload)
    else:
        print('Unknown topic')
