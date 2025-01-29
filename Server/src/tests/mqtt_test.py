import json
import unittest
from unittest.mock import patch, MagicMock

from bson.objectid import ObjectId

# Import the functions to be tested
from src.service.mqtt_service import (
    register_controller,
    predict,
    record_sensor_data,
    record_water_used,
    extract_controller_id,
    CONTROLLER_COLLECTION,
)


class TestMqtt(unittest.TestCase):

    def setUp(self):
        # Mock MongoDB and Redis
        self.mongo_db_mock = MagicMock()
        self.redis_mock = MagicMock()
        self.mqtt_mock = MagicMock()
        self.socketio_mock = MagicMock()

        # Patch the dependencies
        self.mongo_patcher = patch('src.service.mqtt_service.mongo_db', self.mongo_db_mock)
        self.redis_patcher = patch('src.service.mqtt_service.r', self.redis_mock)
        self.mqtt_patcher = patch('src.service.mqtt_service.mqtt', self.mqtt_mock)
        self.socketio_patcher = patch('src.service.mqtt_service.socketio', self.socketio_mock)

        self.mongo_patcher.start()
        self.redis_patcher.start()
        self.mqtt_patcher.start()
        self.socketio_patcher.start()

    def tearDown(self):
        # Stop all patches
        self.mongo_patcher.stop()
        self.redis_patcher.stop()
        self.mqtt_patcher.stop()
        self.socketio_patcher.stop()

    def test_extract_controller_id(self):
        # Test extracting controller ID from topic
        topic = "controller_id/record/sensor_data"
        result = extract_controller_id(topic)
        self.assertEqual(result, "controller_id")

    def test_register_controller_success(self):
        # Test successful controller registration
        payload = json.dumps({"controller_id": "507f1f77bcf86cd799439011"})
        self.mongo_db_mock[CONTROLLER_COLLECTION].insert_one.return_value.inserted_id = ObjectId(
            "507f1f77bcf86cd799439011"
        )

        register_controller(payload)

        # Assert MongoDB insert was called
        self.mongo_db_mock[CONTROLLER_COLLECTION].insert_one.assert_called_once()
        # Assert MQTT subscriptions
        self.mqtt_mock.subscribe.assert_any_call("507f1f77bcf86cd799439011/record/sensor_data")
        self.mqtt_mock.subscribe.assert_any_call("507f1f77bcf86cd799439011/record/water_used")
        self.mqtt_mock.subscribe.assert_any_call("507f1f77bcf86cd799439011/predict")

    def test_register_controller_invalid_payload(self):
        # Test handling of invalid payload
        payload = "invalid_json"
        register_controller(payload)
        # Assert no MongoDB or MQTT calls were made
        self.mongo_db_mock[CONTROLLER_COLLECTION].insert_one.assert_not_called()
        self.mqtt_mock.subscribe.assert_not_called()

    def test_predict(self):
        # Test predict function
        payload = json.dumps({"key": "value"})
        topic = "controller_id/predict"

        predict(payload, topic)

        # Assert no errors occurred
        self.assertTrue(True)  # Placeholder assertion

    def test_record_sensor_data_success(self):
        # Test successful recording of sensor data
        payload = json.dumps({"sensor_data": {"air_temperature": 10, "air_humidity": 10, "soil_humidity": 10},
                              "timestamp": "2023-10-01T00:00:00Z"})
        topic = "507f1f77bcf86cd799439011/record/sensor_data"

        # Mock MongoDB find and update
        self.mongo_db_mock[CONTROLLER_COLLECTION].find_one.return_value = {
            "_id": ObjectId("507f1f77bcf86cd799439011"),
            "record": [],
        }
        self.redis_mock.exists.return_value = True
        self.redis_mock.get.return_value = json.dumps([{"socket_id": "12345"}])

        record_sensor_data(payload, topic)

        # Assert MongoDB update was called
        self.mongo_db_mock[CONTROLLER_COLLECTION].update_one.assert_called_once()
        # Assert Redis and Socket.IO interactions
        self.redis_mock.exists.assert_called_once_with("507f1f77bcf86cd799439011")
        self.socketio_mock.emit.assert_called_once_with("record", json.loads(payload), room="12345")

    def test_record_sensor_data_invalid_payload(self):
        # Test handling of invalid sensor data payload
        payload = json.dumps({"invalid_key": "value"})
        topic = "507f1f77bcf86cd799439011/record/sensor_data"

        record_sensor_data(payload, topic)

        # Assert no MongoDB or Redis calls were made
        self.mongo_db_mock[CONTROLLER_COLLECTION].find_one.assert_not_called()
        self.redis_mock.exists.assert_not_called()

    def test_record_water_used_success(self):
        # Test successful recording of water used data
        payload = json.dumps({"water_used": 100, "timestamp": "2023-10-01T00:00:00Z"})
        topic = "507f1f77bcf86cd799439011/record/water_used"

        # Mock MongoDB find and update
        self.mongo_db_mock[CONTROLLER_COLLECTION].find_one.return_value = {
            "_id": ObjectId("507f1f77bcf86cd799439011"),
            "water_used_month": [],
        }

        record_water_used(payload, topic)

        # Assert MongoDB update was called
        self.mongo_db_mock[CONTROLLER_COLLECTION].update_one.assert_called_once()

    def test_record_water_used_invalid_payload(self):
        # Test handling of invalid water used payload
        payload = json.dumps({"invalid_key": "value"})
        topic = "507f1f77bcf86cd799439011/record/water_used"

        record_water_used(payload, topic)

        # Assert no MongoDB calls were made
        self.mongo_db_mock[CONTROLLER_COLLECTION].find_one.assert_not_called()


if __name__ == '__main__':
    unittest.main()
