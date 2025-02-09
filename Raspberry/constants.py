MQTT_BROKER = "broker.hivemq.com"
MQTT_CLIENT_ID = "micropython-device1234"

SSID = "Lavinia"
PASSWORD = "Lavinia1"


def get_mqtt_topics(device_id):
    """
    Returns the MQTT topics for the given device ID.

    Args:
        device_id (str): The device ID.

    Returns:
        dict: A dictionary containing the MQTT topics.
    """
    return {
        "REGISTER_PUB": "register",
        "RECORD_SENSOR_DATA_PUB": f"{device_id}/record/sensor_data",
        "RECORD_WATER_USED_PUB": f"{device_id}/record/water_used",
        "PREDICT_PUB": f"{device_id}/predict",
        "SCHEDULE_SUB": f"{device_id}/schedule",
        "IRRIGATE_SUB": f"{device_id}/irrigate",
        "PREDICTION_SUB": f"{device_id}/prediction"
    }