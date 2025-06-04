"""
MQTT Event Handlers for IoT Device Communication.

This module defines handlers for MQTT events using the `paho.mqtt.client` library.
It includes functionality for handling connections and processing messages across various topics.

Handlers:
- `handle_connect`: Triggered when the MQTT client establishes a connection with the broker.
- `handle_mqtt_message`: Triggered when a message is received on subscribed topics.

Dependencies:
- `paho.mqtt.client`: For MQTT functionality.
- `src.service.mqtt_service`: Includes service methods for registering devices, making predictions,
recording sensor data, and water usage.
- `src.utils.extensions.mqtt`: MQTT utility extension.

Functionality:
- Handles messages for topics such as:
  - `/record/sensor_data`: Record sensor data from devices.
  - `/predict`: Make predictions based on received data.
  - `/record/water_used`: Record water usage statistics.
  - `register`: Register a new IoT device or device.

Exceptions:
- Handles and logs exceptions during message processing to avoid crashes.
"""

import typing
import paho.mqtt.client
from src.service.mqtt_service import register_device, predict, record_sensor_data, record_water_used
from src.config.protocol import mqtt


@mqtt.on_connect()
def handle_connect(client: paho.mqtt.client.Client, userdata: typing.Any, flags: dict, rc: int):
    """
    Handle MQTT connection events.

    :param client: paho.mqtt.client.Client: The MQTT client instance.
    :param userdata: typing.Any: The private user data provided to the client.
    :param flags: dict: Response flags from the MQTT broker.
    :param rc: int: The connection result code, indicating success or failure.
    """
    print(f"Connected with result code {rc}, client: {client}")


@mqtt.on_message()
def handle_mqtt_message(client: paho.mqtt.client.Client, userdata: typing.Any, message: paho.mqtt.client.MQTTMessage):
    """
    handle incoming MQTT messages.

    :param client: paho.mqtt.client.Client: The MQTT client instance.
    :param userdata: typing.Any: The private user data provided to the client.
    :param message: paho.mqtt.client.MQTTMessage: The received MQTT message containing topic and payload.
    """
    try:
        # Decode the received message payload and log the topic and QoS.
        print(f"Received message '{message.payload.decode()}' on topic '{message.topic}' with QoS {message.qos}")
        topic = message.topic
        payload = message.payload.decode()
    except Exception as e:
        # Log decoding errors and return early.
        print(f"Error: {e}")
        return

    # Process messages based on the topic.
    if topic.endswith('/record/sensor_data'):
        print('Recording sensor data')
        record_sensor_data(payload, topic)
    elif topic.endswith('/predict'):
        print('Processing prediction request')
        predict(payload, topic)
    elif topic.endswith('/record/water_used'):
        print('Recording water usage data')
        record_water_used(payload, topic)
    elif topic == 'register':
        print('Processing registration')
        register_device(payload)
    else:
        # Log unsupported or unrecognized topics.
        print('Unknown topic received')
