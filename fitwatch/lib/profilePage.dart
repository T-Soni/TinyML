// //192.168.255.202
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class Profile extends StatefulWidget {
//   const Profile({super.key});

//   @override
//   State<Profile> createState() => _ProfileState();
// }
// //  Uri.parse('ws://192.168.0.104:9001/data'),
// class _ProfileState extends State<Profile> {
//   Future<Map<String, dynamic>> fetchData() async {

//     final channel = WebSocketChannel.connect(
//   Uri.parse('ws://192.168.0.104:9001'),
// );

// void listenToSensorData() {
//   channel.stream.listen((message) {
//     print("Received raw message: $message");
//     try {

//       final List<dynamic> dataList = jsonDecode(message);
//     final Map<String, dynamic> firstData = dataList[0]; // access first index

//     print("Gyroscope X: ${firstData['gyro_x']}");
//     print("Gyroscope Y: ${firstData['gyro_y']}");
//     print("Gyroscope Z: ${firstData['gyro_z']}");
//       //print('Received Data: $data');

//     } catch (e) {
//       print('Error decoding JSON: $e');
//     }
//   }, onError: (error) {
//     print('WebSocket error: $error');
//   }, onDone: () {
//     print('WebSocket connection closed');
//   });
// }

//     final response = await http.get(
//      Uri.parse('http://192.168.255.202:8000/data'),
//     );
//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception('Failed to load data');
//     }
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade200,
//       appBar: AppBar(
//         title: Text('PROFILE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
//         backgroundColor: Colors.blue.shade100,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back),
//           color: Colors.black,
//           iconSize: 24,
//           onPressed: (){
//             Navigator.pushNamed(context, 'login');
//           },
//           ),
//       ),
//       body: FutureBuilder<Map<String, dynamic>>(
//           future: fetchData(),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting)
//               return Center(child: CircularProgressIndicator());
//             else if (snapshot.hasError)
//               return Center(child: Text("Error: ${snapshot.error}"));
//             else {
//               final data = snapshot.data!;
//               return Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('data'),
//                     Text("Gyroscope X: ${data['gyroscope']['x']}"),
//                     Text("Gyroscope Y: ${data['gyroscope']['z']}"),
//                     Text("Gyroscope Z: ${data['gyroscope']['z']}"),
//                     SizedBox(height: 10),
//                     Text("Speed: ${data['speed']}"),
//                   ],
//                 ),
//               );
//             }
//           },
//         ),
//     );
//   }
// }

/*import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert'; // For JSON parsing

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late MqttServerClient _client;
  String _connectionStatus = "Disconnected";
  double _speed = 0.0;
  double _gyroX = 0.0;
  double _gyroY = 0.0;
  double _gyroZ = 0.0;
  String _rawData = "No data received";
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initMqttClient();
  }

  Future<void> _initMqttClient() async {
    _client = MqttServerClient.withPort('192.168.29.16', 'flutter_client_${DateTime.now().millisecondsSinceEpoch}', 1883);
    _client.logging(on: true);
    _client.keepAlivePeriod = 60;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;

    final connMess = MqttConnectMessage()
        .authenticateAs("username", "password") // Remove if no auth
        .withWillTopic('willtopic')
        .withWillMessage('Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client.connectionMessage = connMess;

    try {
      await _client.connect();
      _subscribeToTopics();
    } catch (e) {
      _updateStatus('Connection failed: $e');
    }
  }

  void _onConnected() {
    _updateStatus('Connected');
    setState(() => _isConnected = true);
  }

  void _onDisconnected() {
    _updateStatus('Disconnected');
    setState(() => _isConnected = false);
  }

  void _subscribeToTopics() {
    _client.subscribe('sensor/data', MqttQos.atLeastOnce);
    _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final MqttPublishMessage message = messages[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
      
      _processIncomingData(payload);
    });
  }

  void _processIncomingData(String payload) {
    setState(() => _rawData = payload);
    
    try {
      final jsonData = jsonDecode(payload);
      setState(() {
        _speed = jsonData['speed']?.toDouble() ?? 0.0;
        _gyroX = jsonData['gyro']?['x']?.toDouble() ?? 0.0;
        _gyroY = jsonData['gyro']?['y']?.toDouble() ?? 0.0;
        _gyroZ = jsonData['gyro']?['z']?.toDouble() ?? 0.0;
      });
    } catch (e) {
      print('JSON parsing error: $e');
    }
  }

  void _updateStatus(String status) {
    setState(() => _connectionStatus = status);
  }

Future<void> _reconnect() async {
  _updateStatus('Reconnecting...');
  try {
    _client.disconnect();  // No await needed
    await _client.connect();
    _subscribeToTopics();
    _updateStatus('Reconnected successfully');
  } catch (e) {
    _updateStatus('Reconnect failed: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.wifi : Icons.wifi_off,
                      color: _isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _connectionStatus,
                      style: TextStyle(
                        color: _isConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Speedometer Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('SPEED', style: TextStyle(color: Colors.grey)),
                    Text(
                      '${_speed.toStringAsFixed(1)} km/h',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    LinearProgressIndicator(
                      value: _speed.clamp(0.0, 100.0) / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _speed > 80 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Gyroscope Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('GYROSCOPE', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildGyroAxis('X', _gyroX),
                        _buildGyroAxis('Y', _gyroY),
                        _buildGyroAxis('Z', _gyroZ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Raw Data
            ExpansionTile(
              title: const Text('Raw Data'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SelectableText(
                    _rawData,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Reconnect Button
            ElevatedButton(
              onPressed: _reconnect,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('RECONNECT'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGyroAxis(String axis, double value) {
    return Column(
      children: [
        Text(
          axis,
          style: const TextStyle(fontSize: 18),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 24,
            color: value.abs() > 1.0 ? Colors.orange : Colors.blue,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _client.disconnect();
    super.dispose();
  }
}*/


import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late MqttServerClient _client;
  String _status = "Disconnected";
  Map<String, dynamic> _currentData = {
    'timestamp': '--:--:--',
    'acc_x': 0.0,
    'acc_y': 0.0,
    'acc_z': 0.0,
    'gyro_x': 0.0,
    'gyro_y': 0.0,
    'gyro_z': 0.0,
    'activity': 'waiting'
  };

  @override
  void initState() {
    super.initState();
    _connectToMqtt();
  }

  Future<void> _connectToMqtt() async {
    // Use actual broker IP (10.0.2.2 for emulator)
    _client =
        MqttServerClient.withPort('192.168.29.16', 'flutter_client', 1883);
    _client.keepAlivePeriod = 30;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;

    try {
      await _client.connect();
      _client.subscribe('wearable/sensor_data', MqttQos.atLeastOnce);
      _client.updates?.listen((messages) {
        final message = messages[0].payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(message.payload.message);
        _updateData(payload);
      });
    } catch (e) {
      setState(() => _status = "Connection failed");
    }
  }

  void _onConnected() {
    setState(() => _status = "Connected");
  }

  void _onDisconnected() {
    setState(() => _status = "Disconnected");
  }

  void _updateData(String payload) {
    try {
      final data = jsonDecode(payload) as List<dynamic>;
      setState(() {
        _currentData = {
          'timestamp': data[0],
          'acc_x': data[1],
          'acc_y': data[2],
          'acc_z': data[3],
          'gyro_x': data[4],
          'gyro_y': data[5],
          'gyro_z': data[6],
          'activity': data[7],
        };
      });
    } catch (e) {
      print("Data parse error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Data'),
        actions: [
          Icon(
            _status == "Connected" ? Icons.wifi : Icons.wifi_off,
            color: _status == "Connected" ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Current Activity
            Card(
              child: ListTile(
                leading: _getActivityIcon(_currentData['activity']),
                title: Text(
                  _currentData['activity'].toString().toUpperCase(),
                  style: const TextStyle(fontSize: 20),
                ),
                subtitle: Text("Last update: ${_currentData['timestamp']}"),
              ),
            ),

            const SizedBox(height: 20),

            // Accelerometer Data
            const Text("ACCELEROMETER",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSensorValue("X", _currentData['acc_x']),
                _buildSensorValue("Y", _currentData['acc_y']),
                _buildSensorValue("Z", _currentData['acc_z']),
              ],
            ),

            const SizedBox(height: 20),

            // Gyroscope Data
            const Text("GYROSCOPE",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSensorValue("X", _currentData['gyro_x']),
                _buildSensorValue("Y", _currentData['gyro_y']),
                _buildSensorValue("Z", _currentData['gyro_z']),
              ],
            ),

            
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Timestamp
                  SizedBox(
                    width: 60,
                    child: Text(
                      _currentData['timestamp'].toString().split(' ').last,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),

                  // Accelerometer
                  _buildSensorChip(
                      'A',
                      '${_currentData['acc_x'].toStringAsFixed(1)}'
                          '/${_currentData['acc_y'].toStringAsFixed(1)}'
                          '/${_currentData['acc_z'].toStringAsFixed(1)}'),

                  // Gyroscope
                  _buildSensorChip(
                      'G',
                      '${_currentData['gyro_x'].toStringAsFixed(1)}'
                          '/${_currentData['gyro_y'].toStringAsFixed(1)}'
                          '/${_currentData['gyro_z'].toStringAsFixed(1)}'),

                  // Activity
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getActivityColor(_currentData['activity']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _currentData['activity']
                          .toString()
                          .substring(0, 3)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
            ),
            const Spacer(),

            // Connection Status
            Text(
              _status,
              style: TextStyle(
                color: _status == "Connected" ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildSensorChip(String label, String value) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: const TextStyle(fontSize: 10)),
      Text(value, style: const TextStyle(fontSize: 12)),
    ],
  );
}

Color _getActivityColor(String activity) {
  switch (activity.toLowerCase()) {
    case 'walking': return Colors.blue;
    case 'running': return Colors.green;
    case 'falling': return Colors.red;
    default: return Colors.grey;
  }
}
  Widget _buildSensorValue(String axis, dynamic value) {
    return Column(
      children: [
        Text(axis, style: const TextStyle(fontSize: 16)),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _getActivityIcon(String activity) {
    switch (activity.toLowerCase()) {
      case 'walking':
        return const Icon(Icons.directions_walk, color: Colors.blue);
      case 'running':
        return const Icon(Icons.directions_run, color: Colors.green);
      case 'falling':
        return const Icon(Icons.warning, color: Colors.red);
      default:
        return const Icon(Icons.access_time, color: Colors.grey);
    }
  }

  @override
  void dispose() {
    _client.disconnect();
    super.dispose();
  }
}
