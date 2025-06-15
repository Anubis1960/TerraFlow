import json
import unittest
from unittest.mock import patch, MagicMock

from bson import ObjectId

from src.config.mongo import USER_COLLECTION, DEVICE_COLLECTION
from src.service.auth_service import (
    handle_form_login,
    handle_token_login,
    handle_register,
    handle_logout,
)
from src.utils.crypt import encrypt
from src.utils.tokenizer import generate_token


class TestAuthService(unittest.TestCase):
    def setUp(self):
        # Mock MongoDB and Redis
        self.mongo_db_mock = {
            USER_COLLECTION: MagicMock(),
            DEVICE_COLLECTION: MagicMock()
        }
        self.redis_mock = MagicMock()

        # Patch the dependencies
        self.mongo_patcher = patch('src.service.auth_service.mongo_db', self.mongo_db_mock)
        self.redis_patcher = patch('src.service.auth_service.r', self.redis_mock)

        self.mongo_patcher.start()
        self.redis_patcher.start()

    def tearDown(self):
        # Stop all patches
        self.mongo_patcher.stop()
        self.redis_patcher.stop()

    def test_handle_form_login_success(self):
        # Test the handle_form_login function
        email = "1@1.1"
        password = "password"
        encrypted_password = encrypt(password)
        user_data = {
            '_id': ObjectId(),
            'email': email,
            'password': encrypted_password,
            'devices': ['507f1f77bcf86cd799439011', '507f1f77bcf86cd79943901a']
        }
        self.mongo_db_mock[USER_COLLECTION].find.return_value = [user_data]
        self.mongo_db_mock[USER_COLLECTION].find_one.return_value = user_data

        # Mock find_one for device collection with side effect
        def device_find_side_effect(query):
            device_id = query["_id"]
            return {
                '_id': device_id,
                'name': f'Device {device_id}'
            }

        self.mongo_db_mock[DEVICE_COLLECTION].find_one.side_effect = device_find_side_effect

        expected_device_data = [
            {'id': '507f1f77bcf86cd799439011', 'name': 'Device 507f1f77bcf86cd799439011'},
            {'id': '507f1f77bcf86cd79943901a', 'name': 'Device 507f1f77bcf86cd79943901a'}
        ]

        result = handle_form_login(email, password)

        self.assertIn('token', result)
        self.assertIn('devices', result)
        self.assertEqual(result['devices'], expected_device_data)

    def test_handle_form_login_invalid_email(self):
        # Test the handle_form_login function with invalid email
        email = "invalid_email"
        password = "password"

        # Call the function
        result = handle_form_login(email, password)

        # Assert that the result contains an error message
        self.assertIn('error', result)
        self.assertEqual(result['error'], 'Invalid email or password')

    def test_handle_form_login_invalid_password(self):
        # Test the handle_form_login function with invalid password
        email = "1@1.1"
        password = "wrong_password"
        encrypted_password = encrypt("password")
        user_data = {
            '_id': ObjectId(),
            'email': email,
            'password': encrypted_password,
            'devices': ['507f1f77bcf86cd79943901a', '507f1f77bcf86cd799439011']
        }
        self.mongo_db_mock[USER_COLLECTION].find.return_value = [user_data]

        # Call the function
        result = handle_form_login(email, password)

        # Assert that the result contains an error message
        self.assertIn('error', result)
        self.assertEqual(result['error'], 'Invalid email or password')

    def test_handle_token_login_success(self):
        # Test the handle_token_login function
        email = "1@1.1"
        user_data = {
            '_id': ObjectId(),
            'email': email,
            'devices': ['device1', 'device2']
        }
        self.mongo_db_mock[USER_COLLECTION].find_one.return_value = user_data

        # Call the function
        result = handle_token_login(email)

        # Assert that the result contains the expected token
        self.assertIn('token', result)
        self.assertEqual(result['token'], generate_token(email, str(user_data['_id'])))

    def test_handle_token_login_new_user(self):
        # Test the handle_token_login function for a new user
        email = "new_user@1.1"
        user_data = {
            '_id': ObjectId(),
            'email': email,
            'devices': []
        }
        self.mongo_db_mock[USER_COLLECTION].find_one.return_value = None
        self.mongo_db_mock[USER_COLLECTION].insert_one.return_value.inserted_id = user_data['_id']

        # Call the function
        result = handle_token_login(email)

        # Assert that the result contains the expected token
        self.assertIn('token', result)

    def test_handle_register_success(self):
        # Test the handle_register function
        email = "1@1.1"
        password = "password"
        encrypted_password = encrypt(password)
        user_data = {
            '_id': ObjectId(),
            'email': email,
            'password': encrypted_password,
            'devices': []
        }
        self.mongo_db_mock[USER_COLLECTION].find.return_value = []
        self.mongo_db_mock[USER_COLLECTION].insert_one.return_value.inserted_id = user_data['_id']

        # Call the function
        result = handle_register(email, password)

        # Assert that the result contains the expected token
        self.assertIn('token', result)
        self.assertEqual(result['token'], generate_token(email, str(user_data['_id'])))

    def test_handle_register_existing_user(self):
        # Test the handle_register function with an existing user
        email = "1@1.1"
        password = "password"
        encrypted_password = encrypt(password)
        user_data = {
            '_id': ObjectId(),
            'email': email,
            'password': encrypted_password,
            'devices': []
        }
        self.mongo_db_mock[USER_COLLECTION].find.return_value = [user_data]

        # Call the function
        result = handle_register(email, password)

        # Assert that the result contains an error message
        self.assertIn('error_msg', result)
        self.assertEqual(result['error_msg'], 'An account with this email already exists')

    def test_handle_logout_success(self):
        # Test the handle_logout function
        user_id = "681785b2abcafa0ae18c75f9"
        device_ids = ["device1", "device2"]
        user_data = {
            '_id': ObjectId(user_id),
            'devices': device_ids
        }
        self.mongo_db_mock[USER_COLLECTION].find_one.return_value = user_data

        # Mock Redis
        self.redis_mock.exists.return_value = True
        self.redis_mock.get.return_value = json.dumps([user_id])

        # Call the function
        result = handle_logout(user_id, device_ids)

        # Assert that the result indicates success
        self.assertIn('success', result)
