"""
IoT Application for an Irrigation System.

This script connects to a Wi-Fi network, communicates with an MQTT broker,
and handles sensor data for an irrigation system. It uses `asyncio` for asynchronous tasks
and generates unique device IDs for registering with the MQTT broker.

Features:
- Generates a unique device ID and stores it persistently in a file.
- Publishes sensor data and water usage data to specific MQTT topics.
- Listens for scheduling and irrigation commands from the MQTT broker.
- Supports asynchronous execution for non-blocking operations.

Modules and Constants:
- `SSID`, `PASSWORD`: Wi-Fi credentials.
- `MQTT_BROKER`, `MQTT_CLIENT_ID`: MQTT broker information.
- `generate_object_id`: Function to create a unique device identifier.

Attributes:
    led (Pin): Represents the onboard LED, used for debugging or status.
    _device_id (str): A unique identifier for this IoT device.
"""

from machine import Pin
from time import sleep, localtime
import network
import os
from umqtt.simple import MQTTClient
import asyncio
import urandom
import ujson as json
from constants import SSID, PASSWORD, HOST, PORT, MQTT_BROKER, MQTT_CLIENT_ID
from generate_id import generate_object_id



class MQTTManager:
    def __init__(self, client):
        self.client = client

    def handle_irrigation_cmd(self):
        """
        Handles the irrigation command.
        """
        timestamp = localtime()
        year, month, day, hour, minute, second = timestamp[:6]
        water_data = {
            'water_used': urandom.randint(0, 100),
            'date': "{:04d}/{:02d}".format(year, month)
        }
        print("Publishing water data:", water_data)
        self.client.publish(RECORD_WATER_USED_PUB, json.dumps(water_data))

    def mqtt_callback(self, topic, msg):
        """
        Handles incoming MQTT messages.

        Args:
            topic (bytes): The topic of the received message.
            msg (bytes): The payload of the received message.
        """
        print('Received message on topic:', topic)
        topic = topic.decode()
        msg = msg.decode()
        if topic == SCHEDULE_SUB:
            json_data = json.loads(msg)
            print("Schedule message:", json_data)
        elif topic == IRRIGATE_SUB:
            print("Irrigation command received:", msg)
            self.handle_irrigation_cmd()

    async def listen(self, period_ms: int = 2000):
        """
        Listens for incoming MQTT messages.

        Args:
            period_ms (int): The interval between checks in milliseconds.
        """
        print("Listening for MQTT messages...")
        while True:
            self.client.check_msg()
            await asyncio.sleep_ms(period_ms)
    
    async def send(self,period_ms: int = 2000):
        """
        Publishes sensor and water usage data to MQTT topics.

        Args:
            client (MQTTClient): The MQTT client instance.
            period_ms (int): The interval between messages in milliseconds.
        """
        while True:
            # Generate timestamp
            timestamp = localtime()
            year, month, day, hour, minute, second = timestamp[:6]

            time_str = "{:04d}/{:02d}/{:02d} {:02d}:{:02d}:{:02d}".format(year, month, day, hour, minute, second)

            # Sensor data
            sensor_data = {
                'sensor_data': {
                    "air_temperature": urandom.randint(0, 100),
                    "air_humidity": urandom.randint(0, 100),
                    "soil_moisture": urandom.randint(0, 100)
                },
                'timestamp': time_str
            }
            print("Publishing sensor data:", sensor_data)
            self.client.publish(RECORD_SENSOR_DATA_PUB, json.dumps(sensor_data))

            await asyncio.sleep_ms(period_ms)

# Initialize onboard LED
led = Pin('LED', Pin.OUT)

changed = False

# Ensure a unique device ID is stored persistently
if 'id.txt' not in os.listdir():
    with open('id.txt', 'w') as f:
        f.write('')  # Create an empty file

with open('id.txt', 'r') as f:
    _device_id = f.read().strip()  # Read and clean up whitespace

if not _device_id:
    changed = True
    _device_id = generate_object_id()
    with open('id.txt', 'w') as f:
        f.write(_device_id)

# MQTT Topics
REGISTER_PUB = "register"
RECORD_SENSOR_DATA_PUB = f"{_device_id}/record/sensor_data"
RECORD_WATER_USED_PUB = f"{_device_id}/record/water_used"
PREDICT_PUB = f"{_device_id}/predict"
SCHEDULE_SUB = f"{_device_id}/schedule"
IRRIGATE_SUB = f"{_device_id}/irrigate"
PREDICTION_SUB = f"{_device_id}/prediction"

def connect_wifi(ssid: str, password: str):
    """
    Connects to a Wi-Fi network.

    Args:
        ssid (str): The Wi-Fi SSID.
        password (str): The Wi-Fi password.
    """
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    wlan.connect(ssid, password)
    print("Connecting to Wi-Fi...")
    while not wlan.isconnected():
        sleep(1)
    print("Connected to Wi-Fi:", wlan.ifconfig()[0])

async def main():
    """
    Main entry point for the IoT application. Handles:
    - Wi-Fi connection.
    - MQTT client setup and subscriptions.
    - Task scheduling for publishing and listening.
    """
    connect_wifi(SSID, PASSWORD)
    print("Device Information:", os.uname())

    client = MQTTClient(MQTT_CLIENT_ID, MQTT_BROKER)
    mqtt_manager = MQTTManager(client)
    client.set_callback(mqtt_manager.mqtt_callback)
    client.connect()
    print("Connected to MQTT broker")

    # Subscribe to topics
    client.subscribe(IRRIGATE_SUB)
    client.subscribe(SCHEDULE_SUB)
    client.subscribe(PREDICTION_SUB)
    print(f"Subscribed to topics: {IRRIGATE_SUB}, {SCHEDULE_SUB}, {PREDICTION_SUB}")

    # Register device
    timestamp = localtime()
    year, month, day, hour, minute, second = timestamp[:6]
    registration_data = {
        'controller_id': _device_id
    }
    client.publish(REGISTER_PUB, json.dumps(registration_data))
    
    if changed:
        sensor_data = {
                'sensor_data': {
                    "air_temperature": 0,
                    "air_humidity": 0,
                    "soil_moisture": 0
                },
                'timestamp': "{:04d}/{:02d}/{:02d} {:02d}:{:02d}:{:02d}".format(year, month, day, hour, minute, second)
            }
        
        water_data = {
            'water_used': 0,
            'date': "{:04d}/{:02d}".format(year, month)
        }

    # Start tasks
    asyncio.create_task(mqtt_manager.listen())
    asyncio.create_task(mqtt_manager.send())

# Run the event loop
loop = asyncio.get_event_loop()
loop.create_task(main())
loop.run_forever()
