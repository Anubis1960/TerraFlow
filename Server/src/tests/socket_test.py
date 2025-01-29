import unittest
from unittest.mock import patch, MagicMock

from bson.objectid import ObjectId

from src.service.socket_service import (
    handle_add_controller,
    handle_remove_controller,
    handle_register,
    handle_login,
    handle_retrieve_controller_data,
    remap_redis
)
from src.util.db import USER_COLLECTION, CONTROLLER_COLLECTION


class TestControllerManagement(unittest.TestCase):

    def setUp(self):
        # Mock MongoDB and Redis
        self.mongo_db_mock = MagicMock()
        self.redis_mock = MagicMock()
        self.socketio_mock = MagicMock()
        self.decrypt_mock = MagicMock()

        # Patch the dependencies
        self.mongo_patcher = patch('src.service.socket_service.mongo_db', self.mongo_db_mock)
        self.redis_patcher = patch('src.service.socket_service.r', self.redis_mock)
        self.socketio_patcher = patch('src.service.socket_service.socketio', self.socketio_mock)
        self.decrypt_patcher = patch('src.util.crypt.decrypt', self.decrypt_mock)

        self.mongo_patcher.start()
        self.redis_patcher.start()
        self.socketio_patcher.start()

    def tearDown(self):
        # Stop all patches
        self.mongo_patcher.stop()
        self.redis_patcher.stop()
        self.socketio_patcher.stop()
        self.decrypt_patcher.stop()

    def test_handle_add_controller(self):
        # Test adding a controller to a user
        user_id = "507f1f77bcf86cd799439011"
        controller_id = "507f1f77bcf86cd799439012"
        socket_id = "socket_id"

        # Mock the user data
        self.mongo_db_mock[USER_COLLECTION].find_one.return_value = {
            '_id': ObjectId(user_id),
            'controllers': []
        }

        # Mock the controller data
        self.mongo_db_mock[CONTROLLER_COLLECTION].find_one.return_value = {
            '_id': ObjectId(controller_id)
        }

        self.redis_mock.exists.return_value = False

        handle_add_controller(controller_id, user_id, socket_id)

        # Assert that the controller was added to the user's list of controllers
        self.mongo_db_mock[USER_COLLECTION].update_one.assert_called_with(
            {'_id': ObjectId(user_id)},
            {'$set': {'controllers': [controller_id]}}
        )

        # Assert that the user was informed that the controller was added
        self.socketio_mock.emit.assert_called_with(
            'controllers',
            {'controllers': [controller_id]},
            room=socket_id
        )

        # Assert that the controller was added to the Redis cache
        self.redis_mock.set.assert_called_with(controller_id,
                                               '[{"user_id": "507f1f77bcf86cd799439011", "socket_id": "socket_id"}]')

    def test_handle_remove_controller(self):
        # Test removing a controller from a user
        user_id = "507f1f77bcf86cd799439011"
        controller_id = "507f1f77bcf86cd799439012"
        socket_id = "socket_id"

        # Mock the user data
        self.mongo_db_mock[USER_COLLECTION].find_one.return_value = {
            '_id': ObjectId(user_id),
            'controllers': [controller_id]
        }

        self.redis_mock.exists.return_value = True
        self.redis_mock.get.return_value = '[{"user_id": "507f1f77bcf86cd799439011", "socket_id": "socket_id"}]'

        handle_remove_controller(controller_id, user_id, socket_id)

        # Assert that the controller was removed from the user's list of controllers
        self.mongo_db_mock[USER_COLLECTION].update_one.assert_called_with(
            {'_id': ObjectId(user_id)},
            {'$set': {'controllers': []}}
        )

        # Assert that the user was informed that the controller was removed
        self.socketio_mock.emit.assert_called_with(
            'controllers',
            {'controllers': []},
            room=socket_id
        )

        # Assert that the controller was removed from the Redis cache
        self.redis_mock.delete.assert_called_with(controller_id)

    def test_handle_register(self):
        # Test registering a new user
        email = "test@test.test"
        password = "password"

        self.mongo_db_mock[USER_COLLECTION].insert_one.return_value.inserted_id = ObjectId("507f1f77bcf86cd799439011")

        result = handle_register(email, password)

        # Assert that the user was registered
        self.assertEqual(result, {'user_id': '507f1f77bcf86cd799439011'})

        # Assert that the user was added to the database
        self.mongo_db_mock[USER_COLLECTION].insert_one.assert_called()

    def test_handle_login(self):
        # Test logging in an existing user
        email = "test@test.test"
        password = "password"

        self.mongo_db_mock[USER_COLLECTION].find_one.return_value = {
            '_id': ObjectId("507f1f77bcf86cd799439011"),
            'email': email,
            'password': password,
            'controllers': []
        }

        self.decrypt_mock.return_value = password

        result = handle_login(email, "12345")

        # Assert that the user was logged in
        self.assertEqual(result, {'user_id': '507f1f77bcf86cd799439011', 'controllers': []})

        # Assert that the user was found in the database
        self.mongo_db_mock[USER_COLLECTION].find_one.assert_called()

    def test_handle_retrieve_controller_data(self):
        # Test retrieving data for a controller
        controller_id = "507f1f77bcf86cd799439012"

        self.mongo_db_mock[CONTROLLER_COLLECTION].find_one.return_value = {
            '_id': ObjectId(controller_id),
            'record': [],
            'water_used_month': []
        }

        handle_retrieve_controller_data(controller_id, 'socket_id')

        self.socketio_mock.emit.assert_called_with(
            'controller_data_response',
            {'record': [], 'water_used_month': []},
            room='socket_id'
        )

        # Assert that the controller data was retrieved from the database
        self.mongo_db_mock[CONTROLLER_COLLECTION].find_one.assert_called()

    def test_remap_redis(self):
        # Test remapping the Redis cache
        controller_id = "507f1f77bcf86cd799439012"
        user_id = "507f1f77bcf86cd799439011"
        socket_id = "socket_id"

        # Mock the Redis cache
        self.redis_mock.exists.return_value = True
        self.redis_mock.get.return_value = '[{"user_id": "507f1f77bcf86cd799439011", "socket_id": "socket_id"}]'

        remap_redis(controller_id, user_id, socket_id)

        # Assert that the Redis cache was updated
        self.redis_mock.set.assert_called()
        self.redis_mock.delete.assert_not_called()


if __name__ == '__main__':
    unittest.main()
