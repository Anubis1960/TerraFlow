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
# moisture_conversion_factor = 100 / (65535)

class MQTTManager:
    def __init__(self, client, topics):
        self.client = client
        self.topics = topics
        self.schedule = {}
        self.schedule_updated_event = asyncio.Event()

    def handle_irrigation_cmd(self):
        """
        Handles the irrigation command.
        """
        timestamp = localtime()
        year, month = timestamp[:2]
        water_data = {
            'water_used': urandom.randint(0, 100),
            'date': "{:04d}/{:02d}".format(year, month)
        }
        print("Publishing water data:", water_data)
        self.client.publish(self.topics['RECORD_WATER_USED_PUB'], json.dumps(water_data))
    
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
            self.client.publish(self.topics['RECORD_SENSOR_DATA_PUB'], json.dumps(sensor_data))

            await asyncio.sleep(period_s)
    
    async def check_irrigation(self, period_s: int = 4):
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
            
            moisture_level = self.read_moisture()
            print("Moisture level:", moisture_level)
            rain_level = self.read_rain()
            print("Rain level:", rain_level)
            temperature, humidity = self.read_dht()
            print("Temperature:", temperature)
            print("Humidity:", humidity)
            self.handle_irrigation_cmd()
    

    def read_moisture(self):
        """
        Reads the moisture level from the sensor.

        Returns:
            float: The moisture level.
        """
        raw_value = moisture_pin.read_u16()
        moisture_level = ((dry_soil - raw_value) / (dry_soil - wet_soil)) * 100
        moisture_level = max(0, min(100, moisture_level))
        return moisture_level
    
    def read_rain(self):
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

    def read_dht(self):
        """
        Reads the temperature and humidity from the DHT sensor.

        Returns:
            tuple: The temperature and humidity.
        """
        try:
            DHT.measure()
            temperature = DHT.temperature()
            humidity = DHT.humidity()
            return temperature, humidity
        except OSError as e:
            print("Error reading DHT sensor:", e)
            return None, None