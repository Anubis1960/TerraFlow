from machine import Pin
from time import sleep
import network
import os
from wsock import WebSocket

HOST = "0.0.0.0"
PORT = 5000

print(os.uname())

led = Pin('LED', Pin.OUT)
    

def connect_wifi(ssid, password):
    import network
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    wlan.connect(ssid, password)
    print("Connecting")
    while not wlan.isconnected():
        pass
    print("Connected to Wi-Fi:", wlan.ifconfig()[0])

def main():
    ssid = "Lavinia"
    password = "Lavinia1"
    connect_wifi(ssid, password)
    print(HOST)
    print(PORT)
    ws = WebSocket(HOST, PORT)
    while True:
        sleep(1)
        try:
            print(send_data('Hello,'))
            print("Attempting to connect to WebSocket server...")
        except Exception as e:
            print("Connection failed:", e)
            sleep(5)  # Wait before trying to reconnect

main()
    
