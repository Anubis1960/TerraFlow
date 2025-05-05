from time import localtime, sleep
import asyncio
import urandom
import ujson as json
from machine import Pin, ADC
import dht

moisture_pin = ADC(Pin(26))
rain_pin = ADC(Pin(27))
wet_soil = 19000
dry_soil = 44300
rain_upper = 65535
rain_lower = 13000
DHT = dht.DHT22(Pin(2))
relay = Pin(16, Pin.OUT)
# moisture_conversion_factor = 100 / (65535)

class MQTTManager:
    def __init__(self, client, topics):
        self.client = client
        self.topics = topics
        self.schedule = {}
        self.schedule_updated_event = asyncio.Event()
        self.current_water_used = 0
        relay_off()

    def handle_irrigation_cmd(self):
        """
        Handles the irrigation command.
        """
        relay_on()
        sleep(5)
        relay_off()
        water_used = urandom.randint(0, 100)
        timestamp = localtime()
        year, month = timestamp[:2]
        water_data = {
            'water_used': water_used,
            'date': "{:04d}/{:02d}".format(year, month)
        }
        self.client.publish(self.topics['RECORD_WATER_USED_PUB'], json.dumps(water_data))
    
    def handle_prediction_cmd(self, json_data):
        """
        Handles the prediction command.
        """
        if json_data['prediction'] == 1: # 1 means ON
            relay_on()
            sleep(5)
            self.current_water_used += 1
            print("Current water used:", self.current_water_used)
            self.send_for_prediction()
        elif json_data['prediction'] == 0: # 0 means OFF
            relay_off()
            timestamp = localtime()
            year, month = timestamp[:2]
            water_data = {
                'water_used': urandom.randint(0, 100),
                'date': "{:04d}/{:02d}".format(year, month)
            }
            print("Publishing water data:", water_data)
            self.client.publish(self.topics['RECORD_WATER_USED_PUB'], json.dumps(water_data))
            self.current_water_used = 0
    
    def handle_schedule_cmd(self, msg):
        """
        Handles the schedule command.
        """

        if 'type' not in msg or 'time' not in msg:
            self.schedule = {}
            self.schedule_updated_event.set()
            return

        type = msg['type']
        time = msg['time']

        if type in ['DAILY', 'WEEKLY', 'MONTHLY']:
            print(f"Schedule type: {type}, Time: {time}")
            self.schedule['type'] = type
            self.schedule['time'] = time
            self.schedule_updated_event.set()


    def mqtt_callback(self, topic, msg):
        """
        Handles incoming MQTT messages.

        Args:
            topic (bytes): The topic of the received message.
            msg (bytes): The payload of the received message.
        """
        topic = topic.decode()
        msg = msg.decode()
        
        if topic == self.topics['SCHEDULE_SUB']:
            json_data = json.loads(msg)
            self.handle_schedule_cmd(json_data)
        elif topic == self.topics['IRRIGATE_SUB']:
            print("Irrigation command received:", msg)
            self.handle_irrigation_cmd()
        elif topic == self.topics['PREDICTION_SUB']:
            print("Prediction command received:", msg)
            json_data = json.loads(msg)
            self.handle_prediction_cmd(json_data)

    async def listen(self, period_s: int = 10):
        """
        Listens for incoming MQTT messages.

        Args:
            period_ms (int): The interval between checks in milliseconds.
        """
        print("Listening for MQTT messages...")
        while True:
            self.client.check_msg()
            await asyncio.sleep(period_s)
    
    async def send(self,period_s: int = 6):
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

            try:
                moisture = read_moisture()
                temperature, humidity = read_dht()
                rain = read_rain()
                print(f"\n\n Moisture level: {moisture}, temp: {temperature}, humidity: {humidity}, rain : {rain} \n\n")
            except OSError as e:
                print("Error reading DHT sensor:", e)
            except Exception as e:
                print("Error reading DHT sensor:", e)
    
            # Sensor data
            sensor_data = {
                'sensor_data': {
                    "temperature": urandom.randint(0, 100),
                    "humidity": urandom.randint(0, 100),
                    "moisture": urandom.randint(0, 100)
                },
                'timestamp': time_str
            }
            self.client.publish(self.topics['RECORD_SENSOR_DATA_PUB'], json.dumps(sensor_data))

            await asyncio.sleep(period_s)
    
    async def check_irrigation(self, period_s: int = 86400):
        """
        If a schedule is set, it follows the schedule.
        """
        while True:
            if self.schedule:
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
            else:
                time_until_irrigation = period_s
            
            while time_until_irrigation > 0:
                delay = min(time_until_irrigation, 86400)  # Wait up to 24 hours at a time
                try:
                    await asyncio.wait_for(self.schedule_updated_event.wait(), delay)
                    self.schedule_updated_event.clear()
                    break  # Exit if the schedule is updated
                except asyncio.TimeoutError:
                    time_until_irrigation -= delay
            
            rain_level = read_rain()
            print("Rain level:", rain_level)

            while rain_level > 50:
                print("Rain detected, irrigation skipped.")
                relay_off()
                await asyncio.sleep(3600)
                rain_level = read_rain()
            
            if time_until_irrigation <= 0:
                self.send_for_prediction()
    
    def send_for_prediction(self):
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
            'timestamp': "{:04d}/{:02d}/{:02d} {:02d}:{:02d}:{:02d}".format(*localtime())
        }))

def get_relay_state():
    """
    Returns the current state of the relay.

    Returns:
        bool: True if the relay is on, False if it is off.
    """
    return relay.value() == 0  # 0 means ON, 1 means OFF

def relay_on():
    print("relay is ON")
    relay.value(0)

def relay_off():
    print("relay is OFF")
    relay.value(1)


def read_dht():
    """
    Reads the temperature and humidity from the DHT sensor.

    Returns:
        tuple: The temperature and humidity.
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

    Returns:
        float: The moisture level.
    """
    raw_value = moisture_pin.read_u16()
    moisture_level = ((dry_soil - raw_value) / (dry_soil - wet_soil)) * 100
    moisture_level = max(0, min(100, moisture_level))
    return moisture_level

def read_rain():
    """
    Reads the rain level from the sensor.

    Returns:
        float: The rain level.
    """
    rain_state = rain_pin.read_u16()
    if rain_state > rain_upper:
        rain_state = 100
    elif rain_state < rain_lower:
        rain_state = 0
    else:
        rain_state = ((rain_upper - rain_state) / (rain_upper - rain_lower)) * 100
    return rain_state