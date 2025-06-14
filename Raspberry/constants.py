from dotenv import get_env_var
MQTT_BROKER = get_env_var("MQTT_BROKER") or "broker.hivemq.com"
MQTT_CLIENT_ID = get_env_var("MQTT_CLIENT_ID") or ""

SSID = get_env_var("SSID") or ""
PASSWORD = get_env_var("PASSWORD") or ""

WEATHER_API_KEY = get_env_var("WEATHER_API_KEY") or ""

DATETIME_API_KEY = get_env_var("DATETIME_API_KEY") or ""


def get_mqtt_topics(device_id: str):
    """
    Returns the MQTT topics for the given device ID.

    :param device_id: str, The device ID.
    :return: dict, A dictionary containing the MQTT topics.
    """
    return {
        "REGISTER_PUB": "register",
        "RECORD_SENSOR_DATA_PUB": f"{device_id}/record/sensor_data",
        "RECORD_WATER_USED_PUB": f"{device_id}/record/water_used",
        "PREDICT_PUB": f"{device_id}/predict",
        "IRRIGATE_SUB": f"{device_id}/irrigate",
        "PREDICTION_SUB": f"{device_id}/prediction",
        "IRRIGATION_TYPE_SUB": f"{device_id}/irrigation_type",
    }