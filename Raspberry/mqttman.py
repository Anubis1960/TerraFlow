from utime import localtime, sleep, time
import asyncio
import ujson as json
from machine import Pin, ADC
import dht
import urequests
from constants import WEATHER_API_KEY
from machine import RTC

moisture_pin = ADC(Pin(26))
rain_pin = ADC(Pin(27))
DHT = dht.DHT22(Pin(2))
relay = Pin(16, Pin.OUT)
water_used_per_second = 0.023  # l/second

class MQTTManager:
    def __init__(self, client, topics, location):
        self.client = client
        self.topics = topics
        self.schedule = {
            'type': "DAILY",
            'time': "08:00",
            'duration': 5,
        }
        self.irrigation_task = asyncio.create_task(self.check_irrigation())
        self.irrigation_type = "AUTOMATIC"
        self.location_data = location
        self.start_water_timer = None
        relay_off()

    def handle_irrigation_cmd(self):
        """
        Handles the irrigation command.
        """
        start_time = time()
        relay_on()
        sleep(5)
        relay_off()
        
        end_time = time()
        duration_seconds = end_time - start_time

        print("Watering started at:", localtime(start_time))
        print("Watering ended at:", localtime(end_time))
        print("Watering duration:", duration_seconds, "seconds")

        water_used = water_used_per_second * duration_seconds
        print("Water used:", water_used, "liters")

        # Record data
        timestamp = localtime()
        year, month = timestamp[:2]
        water_data = {
            'water_used': water_used,
            'date': f"{year:04d}/{month:02d}"
        }
        self.client.publish(self.topics['RECORD_WATER_USED_PUB'], json.dumps(water_data))
    
    def handle_prediction_cmd(self, json_data: dict):
        """
        Handles the prediction command.

        :param json_data: dict
        """
        if self.irrigation_type != 'AUTOMATIC':
            return
        if json_data['prediction'] == 1: # 1 means ON
            if self.start_water_timer == None:
                self.start_water_timer = time()
            relay_on()
            sleep(5)
            self.send_for_prediction()
        elif json_data['prediction'] == 0: # 0 means OFF
            relay_off()
            if self.start_water_timer != None:
                end_time = time()
                duration_seconds = end_time - self.start_water_timer
                print("Watering started at:", localtime(self.start_water_timer))
                print("Watering ended at:", localtime(end_time))
                print("Watering duration:", duration_seconds, "seconds")

                water_used = water_used_per_second * duration_seconds
                print("Water used:", water_used, "liters")

                self.start_water_timer = None
                timestamp = localtime()
                year, month = timestamp[:2]
                water_data = {
                    'water_used': water_used,
                    'date': "{:04d}/{:02d}".format(year, month)
                }
                self.client.publish(self.topics['RECORD_WATER_USED_PUB'], json.dumps(water_data))

    
    def handle_irrigation_type_cmd(self, msg: dict):
        """
        Handles the watering type command.

        :param msg: dict
        """
        if 'irrigation_type' not in msg:
            return

        irrigation_type = msg['irrigation_type']
        if irrigation_type not in ['AUTOMATIC', 'MANUAL', 'SCHEDULED']:
            return

        self.irrigation_task.cancel()

        self.irrigation_type = irrigation_type

        if self.irrigation_type == 'AUTOMATIC':
            self.schedule = {
                'type': "DAILY",
                'time': "08:00",
                'duration': 5,
            }
        elif self.irrigation_type == 'MANUAL':
            self.schedule = {
                'type': "MANUAL",
                'time': "00:00",
                'duration': 5,
            }
        elif self.irrigation_type == 'SCHEDULED':
            if 'schedule' not in msg:
                return
            schedule = msg['schedule']
            if 'type' not in schedule or 'time' not in schedule or 'duration' not in schedule:
                return
            type = schedule['type']
            time = schedule['time']
            try:
                duration = int(schedule['duration'])
            except Exception as e:
                print(e)
                return
            if type in ['DAILY', 'WEEKLY', 'MONTHLY']:
                self.schedule['type'] = type
                self.schedule['time'] = time
                self.schedule['duration'] = duration

        print("Creating task")    
        self.irrigation_task = asyncio.create_task(self.check_irrigation())
        relay_off()
    


    def mqtt_callback(self, topic, msg):
        """
        Handles incoming MQTT messages.

        
        :param topic: bytes, the topic of the received message.
        :param msg: bytes, the payload of the received message.
        """
        topic = topic.decode()
        msg = msg.decode()
        
        if topic == self.topics['IRRIGATE_SUB']:
            print("Irrigation command received:", msg)
            self.handle_irrigation_cmd()
        elif topic == self.topics['PREDICTION_SUB']:
            print("Prediction command received:", msg)
            json_data = json.loads(msg)
            self.handle_prediction_cmd(json_data)
        elif topic == self.topics['IRRIGATION_TYPE_SUB']:
            print("Irrigation type command received:", msg)
            json_data = json.loads(msg)
            self.handle_irrigation_type_cmd(json_data)


    async def listen(self, period_s: int = 10):
        """
        Listens for incoming MQTT messages.

        :param period_ms: int, the interval between checks in seconds.
        """
        print("Listening for MQTT messages...")
        while True:
            self.client.check_msg()
            await asyncio.sleep(period_s)
    
    async def send(self,period_s: int = 6):
        """
        Publishes sensor and water usage data to MQTT topics.

        :param client: MQTTClient, The MQTT client instance.
        :period_ms (int): The interval between messages in seconds.
        """
        while True:
            timestamp = localtime()
            year, month, day, hour, minute, second = timestamp[:6]

            time_str = "{:04d}/{:02d}/{:02d} {:02d}:{:02d}:{:02d}".format(year, month, day, hour, minute, second)

            moisture = read_moisture()
            temperature, humidity = read_dht()
    
            # Sensor data
            sensor_data = {
                'sensor_data': {
                    "temperature": temperature,
                    "humidity": humidity,
                    "moisture": moisture,
                },
                'timestamp': time_str
            }
            self.client.publish(self.topics['RECORD_SENSOR_DATA_PUB'], json.dumps(sensor_data))

            await asyncio.sleep(period_s)
        
    
    async def wait_for_schedule(self):
        """
        Waits until the schedule is over
        """
        schedule_type = self.schedule.get("type")
        schedule_time = self.schedule.get("time")

        # Get current time
        current_time = localtime()
        current_hour, current_minute = current_time[3:5]

        # Extract scheduled hour and minute
        scheduled_hour, scheduled_minute = map(int, schedule_time.split(":"))

        # Calculate seconds until next irrigation
        now_seconds = current_hour * 3600 + current_minute * 60
        schedule_seconds = scheduled_hour * 3600 + scheduled_minute * 60
        time_until_irrigation = schedule_seconds - now_seconds

        # If the time has already passed today, schedule for the next occurrence
        if time_until_irrigation < 0:
            if schedule_type == "DAILY":
                time_until_irrigation += 86400  # 24 hours
            elif schedule_type == "WEEKLY":
                time_until_irrigation += 604800  # 7 days
            elif schedule_type == "MONTHLY":
                time_until_irrigation += 2592000  # 30 days

        print(f"Next irrigation in {time_until_irrigation} seconds")
        
        while time_until_irrigation > 0:
            delay = min(time_until_irrigation, 86400)  # Wait up to 24 hours at a time
            try:
                await asyncio.sleep(delay)
                break  # Exit if the schedule is updated
            except asyncio.TimeoutError:
                time_until_irrigation -= delay


    async def handle_auto_irrigation(self):
        """
        Handles auto irrigation
        """
        await self.wait_for_schedule()
        rain_level = read_rain()
        print("Rain level:", rain_level)

        weather_data = self.get_weather_data()
        print("Weather data:", weather_data)

        weather_rain = weather_data['current']['precip_mm']
        print("Weather rain level:", weather_rain)

        while rain_level > 50 and weather_rain > 5:
            print("Rain detected, irrigation skipped.")
            relay_off()
            await asyncio.sleep(3600)
            rain_level = read_rain()
            weather_data = self.get_weather_data()
            weather_rain = weather_data['current']['precip_mm']
            print("Weather rain level:", weather_rain)
        
        self.send_for_prediction()
    

    async def handle_scheduled_irrigation(self):
        """
        Handles scheduled irrigation
        """
        await self.wait_for_schedule()
        relay_on()
        sleep(self.schedule['duration'])
        relay_off()
        water_used = water_used_per_second * self.schedule['duration']
        print("Water used:", water_used, "liters")
        timestamp = localtime()
        year, month = timestamp[:2]
        water_data = {
            'water_used': water_used,
            'date': "{:04d}/{:02d}".format(year, month)
        }
        self.client.publish(self.topics['RECORD_WATER_USED_PUB'], json.dumps(water_data))
        await asyncio.sleep(60)


    async def check_irrigation(self):
        """
        Check irrigation type and call the correct handler
        """
        print("Irrigation check started.")
        while True:
            if self.irrigation_type == "AUTOMATIC":
                print("Auto mode, checking schedule.")
                await self.handle_auto_irrigation()
            elif self.irrigation_type == "MANUAL":
                print("Manual mode, waiting for irrigation command.")
                await asyncio.sleep(86400)  # Wait for 24 hours
            elif self.irrigation_type == "SCHEDULED":
                print("Scheduled mode, waiting for schedule.")
                await self.handle_scheduled_irrigation()
    

    def send_for_prediction(self):
        """
        Sends data to the server for the model to predict
        """
        moisture_level = read_moisture()
        print("Moisture level:", moisture_level)
        temperature, humidity = read_dht()
        print("Temperature:", temperature)
        print("Humidity:", humidity)
        self.client.publish(self.topics['PREDICT_PUB'], json.dumps({
            'sensor_data': {
                "temperature": temperature,
                "humidity": humidity,
                "moisture": moisture_level
            },
            'timestamp': "{:04d}/{:02d}/{:02d} {:02d}:{:02d}:{:02d}".format(*localtime()[:6])
        }))

    def get_weather_data(self):
        """
        Fetches weather data from the Weather API.

        :return: dict, The weather data.
        """
        url = f"https://api.weatherapi.com/v1/current.json?q={self.location_data['coordinates']}&key={WEATHER_API_KEY}"
        response = urequests.get(url)
        return response.json()


def relay_on():
    print("relay is ON")
    relay.value(0)

def relay_off():
    print("relay is OFF")
    relay.value(1)


def read_dht():
    """
    Reads the temperature and humidity from the DHT sensor.

    :return: tuple, The temperature and humidity.
    """
    count = 0
    while count < 5:
        count += 1
        try:
            DHT.measure()
            temperature = DHT.temperature()
            humidity = DHT.humidity()
            return temperature, humidity
        except OSError as e:
            print("Error reading DHT sensor:", e)
            sleep(2)
        except Exception as e:
            print("Error reading DHT sensor:", e)
            sleep(2)
    
    return 0, 0

def read_moisture():
    """
    Reads the moisture level from the sensor.

    :return: float, soil moisture percentage.
    """
    wet_soil = 19000
    dry_soil = 44300
    raw_value = moisture_pin.read_u16()
    moisture_level = ((dry_soil - raw_value) / (dry_soil - wet_soil)) * 100
    moisture_level = max(0, min(100, moisture_level))
    return moisture_level

def read_rain():
    """
    Reads the precipitation level from the sensor.

    :return: float, precipitation percentage.
    """
    rain_upper = 65535
    rain_lower = 13000
    rain_state = rain_pin.read_u16()
    if rain_state > rain_upper:
        rain_state = 100
    elif rain_state < rain_lower:
        rain_state = 0
    else:
        rain_state = ((rain_upper - rain_state) / (rain_upper - rain_lower)) * 100
    return rain_state