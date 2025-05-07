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

import 'package:flutter/material.dart';
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
}