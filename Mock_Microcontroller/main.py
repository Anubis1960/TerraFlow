import asyncio
import json
from time import localtime

import paho.mqtt.client as mqtt
from dotenv import load_dotenv
import os
import random

load_dotenv()

device_id = "d372fd8aa13bc1dc8e891b2a"

MQTT_BROKER = os.getenv("MQTT_BROKER", "broker.hivemq.com")
MQTT_CLIENT_ID = os.getenv("MQTT_CLIENT_ID", f'mqtt-client-{random.randint(0, 1000)}')
MQTT_PORT = int(os.getenv("MQTT_PORT", 1883))

topics = {
    "REGISTER_PUB": "register",
    "RECORD_SENSOR_DATA_PUB": f"{device_id}/record/sensor_data",
    "RECORD_WATER_USED_PUB": f"{device_id}/record/water_used",
    "PREDICT_PUB": f"{device_id}/predict",
    "SCHEDULE_SUB": f"{device_id}/schedule",
    "IRRIGATE_SUB": f"{device_id}/irrigate",
    "PREDICTION_SUB": f"{device_id}/prediction",
    "IRRIGATION_TYPE_SUB": f"{device_id}/irrigation_type",
}


def handle_irrigation_cmd(client):
    timestamp = localtime()
    year, month = timestamp[:2]
    water_data = {
            'water_used': random.uniform(0.5, 5.0),  # Simulated water usage in liters
            'date': f"{year:04d}/{month:02d}"
    }
    client.publish(topics['RECORD_WATER_USED_PUB'], json.dumps(water_data))


def send_for_prediction(client):
    moisture = random.uniform(0, 100)  # Simulated moisture value
    temperature = random.uniform(15, 35)  # Simulated temperature value
    humidity = random.uniform(30, 90)  # Simulated humidity value
    client.publish(topics['PREDICT_PUB'], json.dumps({
        'sensor_data': {
            "temperature": temperature,
            "humidity": humidity,
            "moisture": moisture
        },
        'timestamp': "{:04d}/{:02d}/{:02d} {:02d}:{:02d}:{:02d}".format(
            *localtime()[:6]
        )
    }))


def handle_prediction_cmd(client, json_data):
    if json_data['prediction'] == 1:  # 1 means ON
        send_for_prediction(client)
    elif json_data['prediction'] == 0:  # 0 means OFF
        timestamp = localtime()
        year, month = timestamp[:2]
        water_data = {
            'water_used': random.uniform(0.5, 5.0),  # Simulated water usage in liters
            'date': "{:04d}/{:02d}".format(year, month)
        }
        client.publish(topics['RECORD_WATER_USED_PUB'], json.dumps(water_data))


def handle_irrigation_type_cmd(client, msg):
    """
    Handles the watering type command.
    """
    if 'irrigation_type' not in msg:
        return

    irrigation_type = msg['irrigation_type']
    if irrigation_type not in ['AUTOMATIC', 'MANUAL', 'SCHEDULED']:
        return

    print(f"Setting irrigation type to {irrigation_type}")

    if irrigation_type == 'AUTOMATIC':
        # Logic for automatic irrigation
        print("Automatic irrigation mode activated.")
        send_for_prediction(client)


async def send(client, period_s: int = 10):
    """
    Sends a message to the MQTT broker every `period_s` seconds.
    """
    while True:
        timestamp = localtime()
        year, month, day, hour, minute, second = timestamp[:6]

        time_str = "{:04d}/{:02d}/{:02d} {:02d}:{:02d}:{:02d}".format(year, month, day, hour, minute, second)

        moisture = random.uniform(0, 100)  # Simulated moisture value
        temperature = random.uniform(15, 35)  # Simulated temperature value
        humidity = random.uniform(30, 90)  # Simulated humidity value

        # Sensor data
        sensor_data = {
            'sensor_data': {
                "temperature": temperature,
                "humidity": humidity,
                "moisture": moisture,
            },
            'timestamp': time_str
        }
        client.publish(topics['RECORD_SENSOR_DATA_PUB'], json.dumps(sensor_data))

        await asyncio.sleep(period_s)


def main():
    client = mqtt.Client(
        client_id=MQTT_CLIENT_ID,
        clean_session=True,
        callback_api_version=mqtt.CallbackAPIVersion.VERSION2
    )

    def on_connect(_client, userdata, flags, rc, properties=None):
        print(f"Connected with result code {rc}")
        _client.subscribe(topics["SCHEDULE_SUB"])
        _client.subscribe(topics["IRRIGATE_SUB"])
        _client.subscribe(topics["PREDICTION_SUB"])
        _client.subscribe(topics["IRRIGATION_TYPE_SUB"])

    client.on_connect = on_connect

    client.connect(MQTT_BROKER, MQTT_PORT)

    def on_message(_client, userdata, msg):
        print(f"Received message: {msg.topic} {msg.payload.decode()}")
        topic = msg.topic
        payload = msg.payload.decode()
        if topic == topics['IRRIGATE_SUB']:
            print("Irrigation command received:", payload)
            handle_irrigation_cmd(_client)
        elif topic == topics['PREDICTION_SUB']:
            print("Prediction command received:", payload)
            json_data = json.loads(payload)
            handle_prediction_cmd(_client, json_data)
        elif topic == topics['IRRIGATION_TYPE_SUB']:
            print("Irrigation type command received:", payload)
            json_data = json.loads(payload)
            handle_irrigation_type_cmd(_client, json_data)

    client.on_message = on_message

    client.connect(MQTT_BROKER)
    client.loop_start()

    registration_data = {
        'device_id': device_id
    }

    client.publish(topics["REGISTER_PUB"], json.dumps(registration_data))

    try:
        asyncio.run(send(client, period_s=10))  # Send sensor data every 10 seconds
        while True:
            asyncio.sleep(1)
    except KeyboardInterrupt:
        print("Exiting...")
    finally:
        client.loop_stop()
        client.disconnect()


if __name__ == "__main__":
    main()
