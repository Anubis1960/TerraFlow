import json
import random
import string
from locust import HttpUser, task, between

USER = {"email": "1@1.1", "password": "1"}
DEVICE_ID = "d372fd8aa13bc0dc8e891b20"
AUTH_BASE_URL = ""
DEVICE_BASE_URL = "/device"
USER_BASE_URL = "/user"


def random_email():
    letters = ''.join(random.choices(string.ascii_lowercase, k=8))
    return f"{letters}@11.com"


def random_password():
    return "password123"


class AuthenticatedDeviceUser(HttpUser):
    wait_time = between(1, 3)
    token = None
    email = None
    password = None

    def on_start(self):
        """Each user registers and logs in independently."""
        self.email = random_email()
        self.password = random_password()

        # Register new user
        register_data = {
            "email": self.email,
            "password": self.password
        }
        register_response = self.client.post(f"{AUTH_BASE_URL}/register", json=register_data)
        if register_response.status_code not in [200, 201]:
            print(f"Registration failed: {register_response.text}")
            self.token = None
            return

        # Log in to get token
        login_data = {
            "email": self.email,
            "password": self.password
        }
        login_response = self.client.post(f"{AUTH_BASE_URL}/login", json=login_data)
        if login_response.status_code == 200:
            self.token = login_response.json().get('token')
        else:
            print(f"Login failed: {login_response.text}")
            self.token = None

        add_device_data = {
            "device_id": DEVICE_ID
        }

        # Add device to user
        add_device_response = self.client.patch(
            f"{USER_BASE_URL}/",
            json=add_device_data,
            headers=self.get_auth_headers()
        )

        if add_device_response.status_code not in [200, 201]:
            print(f"Failed to add device: {add_device_response.text}")
            self.token = None
        else:
            print(f"Device added successfully: {add_device_response.text}")

    def get_auth_headers(self):
        """Returns auth headers if token is valid"""
        if not self.token:
            return {}
        return {"Authorization": f"Bearer {self.token}"}

    @task(5)
    def get_device_data(self):
        """Fetch device data for a known device ID."""
        headers = self.get_auth_headers()
        if not headers:
            return
        with self.client.get(
                f"{DEVICE_BASE_URL}/{DEVICE_ID}/data",
                headers=headers,
        ) as response:
            if response.status_code != 200:
                print(f"Error fetching device data: {response.text}")

    @task(3)
    def update_watering_type(self):
        """Update watering type for a known device."""
        headers = self.get_auth_headers()
        if not headers:
            return
        payload = {
            "watering_type": "auto",
            "schedule": {
                "days": ["Monday", "Wednesday"],
                "time": "10:00 AM"
            }
        }
        with self.client.put(
                f"{DEVICE_BASE_URL}/{DEVICE_ID}/watering_type",
                json=payload,
                headers=headers,
        ) as response:
            if response.status_code not in [200, 204]:
                print(f"Error updating watering type: {response.text}")

    @task(3)
    def rename_device(self):
        """Rename a device."""
        headers = self.get_auth_headers()
        if not headers:
            return
        new_name = f"Updated Name {random.randint(100, 999)}"
        payload = {
            "name": new_name
        }
        with self.client.patch(
                f"{DEVICE_BASE_URL}/{DEVICE_ID}",
                json=payload,
                headers=headers,
        ) as response:
            if response.status_code not in [200, 204]:
                print(f"Error renaming device: {response.text}")

    @task(2)
    def get_user_devices(self):
        """Get all devices associated with the current user."""
        headers = self.get_auth_headers()
        if not headers:
            return
        with self.client.get(
                f"{USER_BASE_URL}/devices",
                headers=headers,
        ) as response:
            if response.status_code != 200:
                print(f"Error fetching user devices: {response.text}")
