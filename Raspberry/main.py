from utime import sleep, localtime
import ntptime
import network
import os
from umqtt.simple import MQTTClient
import asyncio
import ujson as json
from constants import SSID, PASSWORD, MQTT_BROKER, MQTT_CLIENT_ID, get_mqtt_topics, DATETIME_API_KEY
from generate_id import generate_object_id
from mqttman import MQTTManager
import urequests
from machine import RTC

def init():
    """
    Initializes the IoT device by generating a unique device ID.
    """

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
    """
    Fetched the location data from ipinfo

    :return: dict, information about device location
    """
    print("Fetching location data...")
    response = urequests.get('https://ipinfo.io/json')
    data = response.json()
    response.close()
    city = data.get('city', 'Unknown')
    region = data.get('region', 'Unknown')
    country = data.get('country', 'Unknown')
    loc = data.get('loc', 'Unknown')
    timezone = data.get('timezone', 'Unknown')
    return {
        'city': city,
        'region': region,
        'country': country,
        'coordinates': loc,
        'timezone': timezone
    }

def sync_time_with_ip_geolocation_api(rtc, timezone: str):
    """
    Syncs the rtc to current time
    
    :param rtc: RTC
    :param timezone: str
    """

    url = f'http://api.ipgeolocation.io/timezone?apiKey={DATETIME_API_KEY}&tz={timezone}'
    response = urequests.get(url)
    data = response.json()

    print("API Response:", data)

    if 'date_time' in data:
        current_time = data["date_time"]
        print("Current Time String:", current_time)

        if " " in current_time:
            the_date, the_time = current_time.split(" ")
            year, month, mday = map(int, the_date.split("-"))
            hours, minutes, seconds = map(int, the_time.split(":"))

            week_day = data.get("day_of_week", 0)  # Default to 0 if not available
            rtc.datetime((year, month, mday, week_day, hours, minutes, seconds, 0))
            print("RTC Time After Setting:", rtc.datetime())
        else:
            print("Error: Unexpected time format:", current_time)
    else:
        print("Error: The expected data is not present in the response.")

async def main():
    """
    Main entry point for the IoT application. Handles:
    - Wi-Fi connection
    - MQTT client setup and subscriptions
    - Task scheduling
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

    # Get MQTT topics
    topics = get_mqtt_topics(_device_id)

    # Get location data
    location_data = get_location()
    print("Location data:", location_data)

    rtc = RTC()

    sync_time_with_ip_geolocation_api(rtc, location_data['timezone'])


    print(rtc.datetime())

    client = MQTTClient(MQTT_CLIENT_ID, MQTT_BROKER)
    mqtt_mng = MQTTManager(client, topics, location_data)
    client.set_callback(mqtt_mng.mqtt_callback)
    client.connect()
    print("Connected to MQTT broker")

    # Subscribe to topics
    client.subscribe(topics['IRRIGATE_SUB'])
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