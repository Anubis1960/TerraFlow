import unittest
from unittest.mock import patch, MagicMock

from bson import ObjectId

from src.config.mongo import DEVICE_COLLECTION, USER_COLLECTION
from src.service.device_service import handle_get_device_data, handle_update_device


class TestDeviceManagement(unittest.TestCase):
    def setUp(self):
        # Mock MongoDB
        self.mongo_db_mock = {
            USER_COLLECTION: MagicMock(),
            DEVICE_COLLECTION: MagicMock()
        }
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
            'record': [{
                'sensor_data': {
                    'temperature': 25.5,
                    'humidity': 60,
                    'moisture': 30,
                },
                'timestamp': '2025/05/05 05:17:35'
            },
            {
                'sensor_data': {
                    'temperature': 26.0,
                    'humidity': 65,
                    'moisture': 35,
                },
                'timestamp': '2025/05/05 06:17:35'
            },
            {
                'sensor_data': {
                    'temperature': 27.0,
                    'humidity': 70,
                    'moisture': 40,
                },
                'timestamp': '2025/05/05 07:17:35'
            }],
            'water_usage': [{
                'date': '2025/05',
                'water_used': 10,
            },
                {
                'date': '2025/06',
                'water_used': 20,
                }
            ],
        }

        # Mock the MongoDB find_one method
        self.mongo_db_mock[DEVICE_COLLECTION].find_one.return_value = expected_device_data

        # Call the function
        result = handle_get_device_data(device_id)

        # Assert that the result matches the expected device data
        self.assertEqual(result, {
            'record': [{
                'sensor_data': {
                    'temperature': 25.5,
                    'humidity': 60,
                    'moisture': 30,
                },
                'timestamp': '2025/05/05 05:17:35'
            },
                {
                    'sensor_data': {
                        'temperature': 26.0,
                        'humidity': 65,
                        'moisture': 35,
                    },
                    'timestamp': '2025/05/05 06:17:35'
                },
                {
                    'sensor_data': {
                        'temperature': 27.0,
                        'humidity': 70,
                        'moisture': 40,
                    },
                    'timestamp': '2025/05/05 07:17:35'
                }],
            'water_usage': [{
                'date': '2025/05',
                'water_used': 10,
            },
                {
                    'date': '2025/06',
                    'water_used': 20,
                }
            ],
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

    def test_handle_update_device(self):
        # Test the handle_update_device function
        device_id = "681785b2abcafa0ae18c75f9"
        new_device_name = "New Device Name"

        # Mock the MongoDB update_one method
        self.mongo_db_mock[DEVICE_COLLECTION].update_one.return_value.modified_count = 1

        # Call the function
        result = handle_update_device(device_id, new_device_name)

        # Assert that the result is as expected
        self.assertEqual(result, {"message": f"Device {device_id} updated to {new_device_name}"})
