# 🌱 TerraFlow – Intelligent Agriculture System

TerraFlow is an intelligent, IoT-based agricultural monitoring and optimization system designed to help farmers and plant enthusiasts better understand and manage their crops. It combines real-time sensor data, machine learning models, and intuitive user interfaces to deliver actionable insights into soil conditions, water needs, and plant health.

---

## 🔍 About

TerraFlow leverages the power of IoT and Machine Learning to monitor environmental parameters like air temperature, humidity, soil moisture, and rainfall. Using a custom ML model trained on agricultural datasets, it predicts crop water requirements and helps automate irrigation. Additionally, users can upload images of plants to detect diseases using another dedicated image analysis model.

The system includes:
- A **Raspberry Pi Pico W**-based hardware setup for sensor readings.
- A **backend server** in Python Flask with Redis and MongoDB for data processing.
- A **cross-platform Flutter app** for mobile and web access.

---

## ✅ Features

- 📊 Real-time updates from sensors (temperature, humidity, moisture, rainfall).
- 💧 Intelligent irrigation scheduling using a custom ML model.
- 📷 Plant disease detection via image upload.
- ⏰ Manual or automatic irrigation control.
- 📅 Historical data visualization with graphs and statistics.

---

## 🛠️ Installation Guide

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/terraflow.git
cd terraflow
```

---

### 2. Software Requirements

| Component         | Version / Info |
|------------------|----------------|
| Python           | 3.11.0 ([Download](https://www.python.org/downloads/release/python-3110/)) |
| Flutter          | ≥ 3.27.4 ([Stable Channel](https://docs.flutter.dev/install/archive)) |
| MongoDB          | [Installation Guide](https://www.mongodb.com/docs/manual/installation/) |
| Redis             | v7.0.15 ([Install Redis](https://redis.io/docs/latest/operate/oss_and_stack/install/archive/install-redis/)) |

---

### 3. Backend Setup

Navigate to the backend directory:

```bash
cd backend
pip install -r requirements.txt
```

#### Create `.env` file:

```env
HOST=localhost
PORT=5000
ENCRYPT_KEY=your-secret-key-here
MQTT_BROKER=broker.hivemq.com
MQTT_PORT=1883
MONGO_URI=mongodb://localhost:27017
MONGO_DB=terraflow_db
REDIS_HOST=localhost
REDIS_PORT=6379
SECRET_KEY=flask-secret-key
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
SENDER_EMAIL=you@example.com
SENDER_PASSWORD=your-email-password
SMTP_SERVER=smtp.gmail.com
```

> **Note:** For Gmail, enable 2FA and create an app password.

#### Configure Google OAuth

Go to the [Google Cloud Console](https://console.cloud.google.com/) and:
- Create a new OAuth client ID.
- Add redirect URI: `http://{HOST}:{PORT}/auth/callback`
- Set JavaScript origin: `http://{HOST}:{PORT}`

---

### 4. Train or Download Models

You can either train the models yourself or download pre-trained versions:

- **Plant Disease Detection Model**: Use `src/utils/plant_disease.ipynb` and dataset [Plant Disease Classification Merged Dataset](https://www.kaggle.com/datasets/alinedobrovsky/plant-disease-classification-merged-dataset/data)
- **Irrigation Prediction Model**: Use `src/utils/irrigation_models.py` and datasets [Dataset for Predicting watering the plants](https://www.kaggle.com/datasets/nelakurthisudheer/dataset-for-predicting-watering-the-plants), [Soil Moisture, Air temperature, humidity, and Motor on/off Monitoring data](https://data.mendeley.com/datasets/fpdwmm7nrb/1)

Place the trained models in the correct directory inside `/models`.

---

### 5. Frontend Setup

Navigate to the mobile app directory:

```bash
cd mobile_app
flutter pub get
```

Update the API routes in:

```dart
./lib/util/constants.dart
```

Ensure they match your backend host and port:

```dart
const String HOST = 'localhost';
const int PORT = 5000;
```

For Android deployment:
- Generate a signing key:

```bash
keytool -genkey -v -keystore my-release-key.keystore -alias alias_name -keyalg RSA -keysize 2048 -validity 10000
```

- Upload the key to your Google Play Console or Google Cloud account.

---

### 6. Hardware Setup (Optional)

If you're using **Raspberry Pi Pico W**, follow these steps:

- Flash MicroPython: [Download Here](https://micropython.org/download/RPI_PICO_W/)
- Use Thonny IDE or VS Code with Raspberry Pi Pico extension.
- Connect sensors as per the circuit diagram:

 
![Circuit Diagram](https://i.imgur.com/AlghjFM.jpeg)



- Configure .env file


```env
MQTT_BROKER=broker.hivemq.com   
MQTT_CLIENT_ID=pico_sensor_1
SSID=your_wifi_ssid
PASSWORD=your_wifi_password
WEATHER_API_KEY=your_weather_api_key
IPGEOLOCATION_API_KEY=your_ipgeolocation_api_key
```
> **Note:** The mqtt broker should be the same one used in backend environment. 

| API         | Link |
|------------------|----------------|
|  WeatherAPI           | https://www.weatherapi.com/ |
| IpGeolocationAPI          | https://ipgeolocation.io/ |

- Upload code from `./raspberry`

```bash
cd mock_raspberry
pip install -r requirements.txt
```

### 7. Mock Setup (Optional)

If you're not using **Raspberry Pi Pico W**, follow these steps:

Install dependencies

```bash
cd mock_raspberry
pip install -r requirements.txt
```

Configure .env file


```env
MQTT_BROKER=broker.hivemq.com
MQTT_PORT=1883
MQTT_CLIENT_ID=your_mqtt_client_id
```
> **Note:** The mqtt broker should be the same one used in backend environment. 

---

## ▶️ Running the Application

Start Redis:

```bash
systemctl start redis
```

Run the backend server:

```bash
cd backend
python app.py
```

Run the frontend:

```bash
cd mobile_app
flutter run -d web-server   # for web version
flutter list -d             # list available devices
flutter run -d <device>     # run on mobile device
```

(Optional) Start mock Raspberry Pi connection:

```bash
cd mock_raspberry
python mock.py
```

---

## 📚 Documentation

### Backend API Docs

Generate HTML docs using `pdoc`:

```bash
pdoc -html ./backend/src --output-dir docs/backend
```

### Frontend Dart Docs

```bash
cd mobile_app
dart doc
```

---

## 📂 Project Structure Overview

```
terraflow/
├── backend/              # Flask server with APIs and ML integration
├── mobile_app/           # Flutter cross-platform application
├── raspberry/            # MicroPython code for Raspberry Pi Pico W
└── mock_raspberry/       # Simulated sensor data for testing
```

---

## 🤝 Contributions

If you'd like to improve TerraFlow, feel free to submit issues or pull requests.

---
