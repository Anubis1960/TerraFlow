import unittest
from unittest.mock import patch, MagicMock
from bson import ObjectId
from src.service.user_service import (
    handle_get_user_devices,
    handle_add_device,
    handle_delete_device,
)
from src.config.mongo import USER_COLLECTION, DEVICE_COLLECTION


class TestUserManagement(unittest.TestCase):
    def setUp(self):
        # Mock MongoDB and Redis
        self.mongo_db_mock = MagicMock()
        self.redis_mock = MagicMock()

        # Patch the dependencies
        self.mongo_patcher = patch('src.service.user_service.mongo_db', self.mongo_db_mock)
        self.redis_patcher = patch('src.service.user_service.r', self.redis_mock)

        self.mongo_patcher.start()
        self.redis_patcher.start()

    def tearDown(self):
        # Stop all patches
        self.mongo_patcher.stop()
        self.redis_patcher.stop()

    def test_handle_get_user_devices(self):
        # Test fetching devices for a user
        user_id = "681785b2abcafa0ae18c75f9"
        expected_devices = ["device1", "device2"]

        # Mock the user data
        self.mongo_db_mock[USER_COLLECTION].find_one.return_value = {
            '_id': ObjectId(user_id),
            'devices': expected_devices
        }

        devices = handle_get_user_devices(user_id)

        print('devices:', devices)

        # Assert that the correct devices were returned
        self.assertEqual(devices, expected_devices)

    def test_handle_get_user_devices_user_not_found(self):
        # Test fetching devices for a user that does not exist
        user_id = "681785b2abcafa0ae18c75f9"

        # Mock the user data
        self.mongo_db_mock[USER_COLLECTION].find_one.return_value = None

        devices = handle_get_user_devices(user_id)

        # Assert that None is returned when user is not found
        self.assertIsNone(devices)

    def test_handle_add_device(self):
        # Test adding a device to a user
        user_id = "681785b2abcafa0ae18c75f9"
        device_id = "d372fd8aa13bc0dc8e891b20"

        # Mock the user data
        self.mongo_db_mock[USER_COLLECTION].find_one.return_value = {
            '_id': ObjectId(user_id),
            'devices': []
        }

        # Mock the device data
        self.mongo_db_mock[DEVICE_COLLECTION].find_one.return_value = {
            '_id': ObjectId(device_id)
        }

        self.redis_mock.exists.return_value = False

        result = handle_add_device(device_id, user_id)

        # Assert that the device was added to the user's list of devices
        self.mongo_db_mock[USER_COLLECTION].update_one.assert_called_with(
            {'_id': ObjectId(user_id)},
            {'$set': {'devices': [device_id]}}
        )

        self.redis_mock.set.assert_called_with(
            f'device:{device_id}',
            '["681785b2abcafa0ae18c75f9"]'
        )

        # Assert that the function returned True
        self.assertTrue(result)

    def test_handle_add_device_user_not_found(self):
        # Test adding a device to a user that does not exist
        user_id = "681785b2abcafa0ae18c75f9"
        device_id = "d372fd8aa13bc0dc8e891b20"

        # Mock the user data
        self.mongo_db_mock[USER_COLLECTION].find_one.return_value = None

        result = handle_add_device(device_id, user_id)

        # Assert that the function returned False
        self.assertFalse(result)

    def test_handle_add_device_device_not_found(self):
        # Test adding a device that does not exist
        user_id = "681785b2abcafa0ae18c75f9"
        device_id = "d372fd8aa13bc0dc8e891b20"

        # Mock the user data
        self.mongo_db_mock[USER_COLLECTION].find_one.return_value = {
            '_id': ObjectId(user_id),
            'devices': []
        }

        # Mock the device data
        self.mongo_db_mock[DEVICE_COLLECTION].find_one.return_value = None

        result = handle_add_device(device_id, user_id)

        # Assert that the function returned False
        self.assertFalse(result)

    def test_handle_delete_device(self):
        # Test deleting a device from a user
        user_id = "681785b2abcafa0ae18c75f9"
        device_id = "d372fd8aa13bc0dc8e891b20"

        # Mock the user data
        self.mongo_db_mock[USER_COLLECTION].find_one.return_value = {
            '_id': ObjectId(user_id),
            'devices': [device_id]
        }

        self.redis_mock.exists.return_value = True
        self.redis_mock.get.return_value = '["681785b2abcafa0ae18c75f9"]'

        result = handle_delete_device(device_id, user_id)

        # Assert that the device was removed from the user's list of devices
        self.mongo_db_mock[USER_COLLECTION].update_one.assert_called_with(
            {'_id': ObjectId(user_id)},
            {'$set': {'devices': []}}
        )

        # Assert that the device was removed from Redis
        self.redis_mock.set.assert_called_with(
            f'device:{device_id}',
            '[]'
        )

        # Assert that the function returned True
        self.assertTrue(result)

    def test_handle_delete_device_user_not_found(self):
        # Test deleting a device from a user that does not exist
        user_id = "681785b2abcafa0ae18c75f9"
        device_id = "d372fd8aa13bc0dc8e891b20"

        # Mock the user data
        self.mongo_db_mock[USER_COLLECTION].find_one.return_value = None

        result = handle_add_device(device_id, user_id)

        # Assert that the function returned False
        self.assertFalse(result)