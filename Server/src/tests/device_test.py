import unittest
from unittest.mock import patch, MagicMock
from bson import ObjectId

from src.service.device_service import handle_get_device_data

from src.config.mongo import mongo_db, DEVICE_COLLECTION

class TestDeviceManagement(unittest.TestCase):
    def setUp(self):
        # Mock MongoDB
        self.mongo_db_mock = MagicMock()
        self.mongo_patcher = patch('src.service.device_service.mongo_db', self.mongo_db_mock)
        self.mongo_patcher.start()

    def tearDown(self):
        # Stop all patches
        self.mongo_patcher.stop()

    def test_handle_get_device_data(self):
        # Test the handle_get_device_data function
        device_id = "681785b2abcafa0ae18c75f9"
        expected_device_data = {
            '_id': ObjectId(device_id),
            'record': [1, 2, 3],
            'water_usage': [10, 20, 30],
        }

        # Mock the MongoDB find_one method
        self.mongo_db_mock[DEVICE_COLLECTION].find_one.return_value = expected_device_data

        # Call the function
        result = handle_get_device_data(device_id)

        # Assert that the result matches the expected device data
        self.assertEqual(result, {
            'record': [1, 2, 3],
            'water_usage': [10, 20, 30],
        })

    def test_handle_get_device_data_not_found(self):
        # Test the handle_get_device_data function when device is not found
        device_id = "681785b2abcafa0ae18c75f9"

        # Mock the MongoDB find_one method to return None
        self.mongo_db_mock[DEVICE_COLLECTION].find_one.return_value = None

        # Call the function
        result = handle_get_device_data(device_id)

        # Assert that the result is None
        self.assertIsNone(result)