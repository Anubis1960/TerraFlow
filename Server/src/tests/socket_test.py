import json
import unittest
from unittest.mock import patch, MagicMock

from bson.objectid import ObjectId

from src.config.mongo import USER_COLLECTION
from src.service.socket_service import (
    remap_redis,
    handle_irrigate,
    handle_schedule_irrigation,
)


class TestDeviceManagement(unittest.TestCase):

    def setUp(self):
        # Mock MongoDB and Redis
        self.mongo_db_mock = MagicMock()
        self.redis_mock = MagicMock()
        self.socketio_mock = MagicMock()
        self.mqtt_mock = MagicMock()

        # Patch the dependencies
        self.mongo_patcher = patch('src.service.socket_service.mongo_db', self.mongo_db_mock)
        self.redis_patcher = patch('src.service.socket_service.r', self.redis_mock)
        self.socketio_patcher = patch('src.service.socket_service.socketio', self.socketio_mock)
        self.mqtt_patcher = patch('src.service.socket_service.mqtt', self.mqtt_mock)

        self.mongo_patcher.start()
        self.redis_patcher.start()
        self.socketio_patcher.start()
        self.mqtt_patcher.start()

    def tearDown(self):
        # Stop all patches
        self.mongo_patcher.stop()
        self.redis_patcher.stop()
        self.socketio_patcher.stop()
        self.mqtt_patcher.stop()

    def test_handle_irrigate(self):
        # Test the handle_irrigate function
        device_id = "681785b2abcafa0ae18c75f9"
        expected_topic = f'{device_id}/irrigate'
        expected_payload = {'irrigate': True}

        # Call the function
        handle_irrigate(device_id)

        # Assert that the MQTT publish method was called with the correct parameters
        self.mqtt_mock.publish.assert_called_once_with(expected_topic, json.dumps(expected_payload))

    def test_handle_schedule_irrigation(self):
        # Test the handle_schedule_irrigation function
        device_id = "681785b2abcafa0ae18c75f9"
        schedule = {
            'type': 'DAILY',
            'time': '00:00',
        }
        expected_topic = f'{device_id}/schedule'
        expected_payload = schedule

        # Call the function
        handle_schedule_irrigation(device_id, schedule)

        # Assert that the MQTT publish method was called with the correct parameters
        self.mqtt_mock.publish.assert_called_once_with(expected_topic, json.dumps(expected_payload))

    def test_remap_redis(self):
        # Test remapping the Redis cache
        device_id = "681785b2abcafa0ae18c75f9"
        user_id = "d372fd8aa13bc0dc8e891b20"
        socket_id = "d372fd8aa13bc0dc8e891b20"

        # Mock the MongoDB find_one method
        self.mongo_db_mock[USER_COLLECTION].find_one.return_value = {
            '_id': ObjectId(user_id),
            'devices': [ObjectId(device_id)]
        }

        # Mock the Redis set method
        self.redis_mock.get.return_value = json.dumps([user_id])
        # Call the function
        remap_redis(device_id, user_id, socket_id)
        # Assert that the Redis set method was called with the correct parameters
        # self.redis_mock.set.assert_called_with(f'device:{device_id}', json.dumps([user_id]))
        self.redis_mock.set.assert_called_with(f'user:{user_id}', socket_id)

    def test_remap_redis_no_device(self):
        # Test remapping Redis when the device does not exist
        device_id = "non_existent_device"
        user_id = "d372fd8aa13bc0dc8e891b20"
        socket_id = "d372fd8aa13bc0dc8e891b20"

        # Mock the Redis get method to return None
        self.redis_mock.get.return_value = None

        # Call the function
        remap_redis(device_id, user_id, socket_id)

        # Assert that the Redis set method was not called
        self.redis_mock.set.assert_not_called()
