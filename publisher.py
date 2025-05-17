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

# import paho.mqtt.client as mqtt
# import json
# import time
# import random
# from datetime import datetime
# import math

# # Constants
# GRAVITY = 9.81  # m/s²
# ACTIVITIES = ["walking", "stairs_up", "stairs_down", "sitting", "standing", "laying"]

# # State variables
# current_activity = "standing"
# last_value = {"acc_x": 0, "acc_y": 0, "acc_z": GRAVITY}

# def generate_realistic_acceleration(activity):
#     """Generates realistic accelerometer data for different activities"""
#     global last_value

#     # Base values for each activity
#     bases = {
#         "standing": {"x": (0, 0), "y": (0, 0), "z": (GRAVITY, GRAVITY)},
#         "walking": {"x": (-1.5, 1.5), "y": (-0.5, 0.5), "z": (GRAVITY-0.3, GRAVITY+0.3)},
#         "stairs_up": {"x": (-2, 2), "y": (-1, 1), "z": (GRAVITY-0.5, GRAVITY+1)},
#         "stairs_down": {"x": (-3, 3), "y": (-1.5, 1.5), "z": (GRAVITY-1, GRAVITY+0.5)},
#         "sitting": {"x": (-0.5, 0.5), "y": (-0.5, 0.5), "z": (GRAVITY-0.2, GRAVITY+0.2)},
#         "laying": {"x": (-0.3, 0.3), "y": (-0.3, 0.3), "z": (GRAVITY-0.1, GRAVITY+0.1)},
#     }

#     # Smooth transition between values
#     def smooth_transition(current, target_range, factor=0.2):
#         target = random.uniform(*target_range)
#         return current + (target - current) * factor

#     last_value["acc_x"] = smooth_transition(last_value["acc_x"], bases[activity]["x"])
#     last_value["acc_y"] = smooth_transition(last_value["acc_y"], bases[activity]["y"])
#     last_value["acc_z"] = smooth_transition(last_value["acc_z"], bases[activity]["z"])

#     # Add some realistic noise
#     noise = 0.1
#     return [
#         round(last_value["acc_x"] + random.uniform(-noise, noise), 2),
#         round(last_value["acc_y"] + random.uniform(-noise, noise), 2),
#         round(last_value["acc_z"] + random.uniform(-noise, noise), 2)
#     ]

# def change_activity():
#     """Change activity every 5-10 seconds"""
#     global current_activity
#     current_activity = random.choice(ACTIVITIES)
#     return current_activity

# # MQTT Setup
# client = mqtt.Client(protocol=mqtt.MQTTv311)
# client.connect("localhost", 1883, 60)

# try:
#     last_activity_change = time.time()
#     while True:
#         # Change activity randomly
#         if time.time() - last_activity_change > random.randint(5, 10):
#             activity = change_activity()
#             last_activity_change = time.time()
#         else:
#             activity = current_activity

#         # Generate realistic data
#         acc_x, acc_y, acc_z = generate_realistic_acceleration(activity)
#         gyro_x, gyro_y, gyro_z = [round(random.uniform(-2, 2), 2) for _ in range(3)]

#         payload = json.dumps({
#             "timestamp": datetime.now().strftime("%H:%M:%S.%f"),
#             "acc_x": acc_x,
#             "acc_y": acc_y,
#             "acc_z": acc_z,
#             "gyro_x": gyro_x,
#             "gyro_y": gyro_y,
#             "gyro_z": gyro_z,
#             "activity": activity
#         })

#         client.publish("wearable/sensor_data", payload)
#         print(f"Published: {payload}")
#         time.sleep(0.02)  # 50Hz

# except KeyboardInterrupt:
#     print("\nPublisher stopped")
#     client.disconnect()
