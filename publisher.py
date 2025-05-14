import paho.mqtt.client as mqtt
import json
import time
import random
from datetime import datetime

# MQTT Setup
client = mqtt.Client()  # Client ID
client.connect("localhost", 1883, 60) # 60s is the keep alive time

# Sensor data generators (realistic ranges for wearables)
def generate_acceleration():
    return [round(random.uniform(-20.0, 20.0), 2) for _ in range(3)]  # acc_x, acc_y, acc_z
    # returns a list of 3 random values

def generate_gyro():
    return [round(random.uniform(-10.0, 10.0), 2) for _ in range(3)]  # gyro_x, gyro_y, gyro_z

def get_activity():
    activities = ["walking", "walking_upstairs", "walking_downstairs", "sitting", "standing", "laying"]
    return random.choice(activities)

try:
    while True:
        # Generate 50 datasets per second (20ms interval)
        for _ in range(50):
            timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]  # HH:MM:SS.milliseconds
            acc_x, acc_y, acc_z = generate_acceleration()
            gyro_x, gyro_y, gyro_z = generate_gyro()
            activity = get_activity()
            
            payload = json.dumps({
                'timestamp': datetime.now().strftime("%H:%M:%S.%f"),
                'acc_x': acc_x,
                'acc_y': acc_y,
                'acc_z': acc_z,
                'gyro_x': gyro_x,
                'gyro_y': gyro_y,
                'gyro_z': gyro_z,
                'activity': activity
            })
            client.publish("wearable/sensor_data", payload)
            print(f"Published: {payload}")
            time.sleep(0.02)  # 20ms delay for 50Hz frequency

except KeyboardInterrupt:
    print("\nPublisher stopped")
    client.disconnect()