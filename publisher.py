import paho.mqtt.client as mqtt
import json
import time
import random

# MQTT Client Setup
client = mqtt.Client()
client.connect("localhost", 1883, 60)  # Connect to local Mosquitto broker

# Realistic data generators
def generate_speed():
    """Generate speed values between 0-120 km/h with gradual changes"""
    return round(random.uniform(0, 120), 1)

def generate_gyro():
    """Generate gyroscope readings with realistic movement patterns"""
    return {
        'x': round(random.uniform(-2.0, 2.0), 2),  # Roll
        'y': round(random.uniform(-2.0, 2.0), 2),  # Pitch
        'z': round(random.uniform(-0.5, 0.5), 2)   # Yaw (typically less movement)
    }

try:
    while True:
        # Create minimal JSON payload
        payload = {
            "speed": generate_speed(),
            "gyro": generate_gyro()
        }

        # Convert to JSON and publish
        json_payload = json.dumps(payload)
        client.publish("sensor/data", json_payload)  # Using different topic
        print(f"Published: {json_payload}")
        
        time.sleep(5)  # Send data every 100ms (adjust as needed)

except KeyboardInterrupt:
    print("\nPublisher stopped")
    client.disconnect()
