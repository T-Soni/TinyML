# import paho.mqtt.client as mqtt
# import json
# import time
# import random

# # MQTT Client Setup
# client = mqtt.Client()
# client.connect("localhost", 1883, 60)  # Connect to local Mosquitto broker

# # Realistic data generators
# def generate_speed():
#     """Generate speed values between 0-120 km/h with gradual changes"""
#     return round(random.uniform(0, 120), 1)

# def generate_gyro():
#     """Generate gyroscope readings with realistic movement patterns"""
#     return {
#         'x': round(random.uniform(-2.0, 2.0), 2),  # Roll
#         'y': round(random.uniform(-2.0, 2.0), 2),  # Pitch
#         'z': round(random.uniform(-0.5, 0.5), 2)   # Yaw (typically less movement)
#     }

# try:
#     while True:
#         # Create minimal JSON payload
#         payload = {
#             "speed": generate_speed(),
#             "gyro": generate_gyro()
#         }

#         # Convert to JSON and publish
#         json_payload = json.dumps(payload)
#         client.publish("sensor/data", json_payload)  # Using different topic
#         print(f"Published: {json_payload}")
        
#         time.sleep(5)  # Send data every 100ms (adjust as needed)

# except KeyboardInterrupt:
#     print("\nPublisher stopped")
#     client.disconnect()

import paho.mqtt.client as mqtt
import json
import time
import random
from datetime import datetime

# MQTT Setup
client = mqtt.Client()  # Client ID
client.connect("localhost", 1883, 60)

# Sensor data generators (realistic ranges for wearables)
def generate_acceleration():
    return [round(random.uniform(-20.0, 20.0), 2) for _ in range(3)]  # acc_x, acc_y, acc_z

def generate_gyro():
    return [round(random.uniform(-10.0, 10.0), 2) for _ in range(3)]  # gyro_x, gyro_y, gyro_z

def get_activity():
    activities = ["walking", "running", "idle", "falling"]
    return random.choice(activities)

try:
    while True:
        # Generate 50 datasets per second (20ms interval)
        for _ in range(50):
            timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]  # HH:MM:SS.milliseconds
            acc_x, acc_y, acc_z = generate_acceleration()
            gyro_x, gyro_y, gyro_z = generate_gyro()
            activity = get_activity()
            
            payload = [
                timestamp,
                acc_x, acc_y, acc_z,
                gyro_x, gyro_y, gyro_z,
                activity
            ]
            
            client.publish("wearable/sensor_data", json.dumps(payload))
            print(f"Published: {payload}")
            time.sleep(0.02)  # 20ms delay for 50Hz frequency

except KeyboardInterrupt:
    print("\nPublisher stopped")
    client.disconnect()