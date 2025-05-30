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
    _device_id (str): A unique identifier for this IoT device.
"""

from time import sleep, localtime
import ntptime
import network
import os
from umqtt.simple import MQTTClient
import asyncio
import ujson as json
from constants import SSID, PASSWORD, MQTT_BROKER, MQTT_CLIENT_ID, get_mqtt_topics
from generate_id import generate_object_id
from mqttman import MQTTManager
import requests
from machine import RTC

def init():
    """
    Initializes the IoT device by synchronizing the time and generating a unique device ID.
    """
    try:
        ntptime.host = "pool.ntp.org"
        ntptime.settime()
    except OSError as e:
        print("Error synchronizing time:", e)

    # Ensure a unique device ID is stored persistently
    if 'id.txt' not in os.listdir():
        with open('id.txt', 'w') as f:
            f.write('')  # Create an empty file

    with open('id.txt', 'r') as f:
        _device_id = f.read().strip()  # Read and clean up whitespace

    if not _device_id:
        _device_id = generate_object_id()
        with open('id.txt', 'w') as f:
            f.write(_device_id)
    
    return _device_id

def get_location():
    print("Fetching location data...")
    response = requests.get('https://ipinfo.io/json')
    data = response.json()
    response.close()
    city = data.get('city', 'Unknown')
    region = data.get('region', 'Unknown')
    country = data.get('country', 'Unknown')
    loc = data.get('loc', 'Unknown')
    return {
        'city': city,
        'region': region,
        'country': country,
        'coordinates': loc,
    }


def get_world_time():
    url = "http://worldtimeapi.org/api/ip"
    print("Fetching time data...")
    try:
        response = requests.get(url)
        if response.status_code == 200:
            data = response.json()
            response.close()
            return data
        else:
            print("Failed to retrieve data. Status code:", response.status_code)
            response.close()
            return None
    except Exception as e:
        print("Error fetching data:", e)
        return None

# Set internal RTC with local time
def set_rtc_from_unix(unixtime, utc_offset_seconds):
    # Convert Unix timestamp + offset to local time tuple
    local_seconds = unixtime + utc_offset_seconds
    tm = localtime(local_seconds)

    # Format as RTC tuple: (year, month, day, weekday, hour, minute, second, subsecond)
    rtc_tuple = (tm[0], tm[1], tm[2], tm[6] + 1, tm[3], tm[4], tm[5], 0)
    RTC().datetime(rtc_tuple)
    print("RTC set to:", tm[0], tm[1], tm[2], tm[3], tm[4], tm[5])

async def main():
    """
    Main entry point for the IoT application. Handles:
    - Wi-Fi connection.
    - MQTT client setup and subscriptions.
    - Task scheduling for publishing and listening.
    """
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    wlan.connect(SSID, PASSWORD)
    print("Connecting to Wi-Fi...")
    while not wlan.isconnected():
        sleep(1)
        print(".", end="")
    print("Connected to Wi-Fi:", wlan.ifconfig()[0])

    # Initialize device ID
    _device_id= init()

    time_data = get_world_time()

    if time_data:
        unixtime = time_data["unixtime"]
        utc_offset = time_data["raw_offset"] + time_data.get("dst_offset", 0)
        print("UTC Offset (with DST): {} seconds".format(utc_offset))

        set_rtc_from_unix(unixtime, utc_offset)

    # Get MQTT topics
    topics = get_mqtt_topics(_device_id)

    # Get location data
    location_data = get_location()
    print("Location data:", location_data)

    client = MQTTClient(MQTT_CLIENT_ID, MQTT_BROKER)
    mqtt_mng = MQTTManager(client, topics, location_data)
    client.set_callback(mqtt_mng.mqtt_callback)
    client.connect()
    print("Connected to MQTT broker")

    # Subscribe to topics
    client.subscribe(topics['IRRIGATE_SUB'])
    client.subscribe(topics['SCHEDULE_SUB'])
    client.subscribe(topics['PREDICTION_SUB'])
    client.subscribe(topics['IRRIGATION_TYPE_SUB'])

    registration_data = {
        'device_id': _device_id
    }
    client.publish(topics['REGISTER_PUB'], json.dumps(registration_data))

    # Start tasks
    asyncio.create_task(mqtt_mng.listen())
    asyncio.create_task(mqtt_mng.send())


# Run the event loop
loop = asyncio.get_event_loop()
loop.create_task(main())
loop.run_forever()