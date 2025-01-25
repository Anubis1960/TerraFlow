import json
from flask_socketio import emit
from src.util.extensions import socketio, mqtt
import datetime

@mqtt.on_connect()
def handle_connect(client, userdata, flags, rc):
    print('Connected')
    print(client)
    print(userdata)
    print(flags)
    print(rc)
    mqtt.subscribe('home/device/commands')
    mqtt.subscribe('register')

@mqtt.on_message()
def handle_mqtt_message(client, userdata, message):
    print('Message received')
    print(client)
    print(userdata)
    print(message)
    socketio.emit('mqtt_message', {'topic': message.topic, 'payload': message.payload.decode()})

@socketio.on('connect')
def handle_connect():
    print('Client connected')
    emit('mqtt_message', {'topic': 'test', 'payload': 'test'})

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

@socketio.on('message')
def handle_message(data):
    print('Message received')
    json_data = {
        'message': data['message'],
        'timestamp': datetime.datetime.now().isoformat()
    }
    print(json_data)
    json_str = json.dumps(json_data)
    mqtt.publish('home/device/commands', json_str)

@socketio.on('mqtt_publish')
def handle_mqtt_publish(data):
    print('Publishing message')
    print(data)
    mqtt.publish(data['topic'], data['payload'])

@socketio.on('mqtt_subscribe')
def handle_mqtt_subscribe(data):
    print('Subscribing to topic')
    print(data)
    mqtt.subscribe(data['topic'])

@socketio.on('mqtt_unsubscribe')
def handle_mqtt_unsubscribe(data):
    print('Unsubscribing from topic')
    print(data)
    mqtt.unsubscribe(data['topic'])

