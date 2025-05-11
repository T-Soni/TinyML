import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';

class DataLogs extends StatefulWidget {
  const DataLogs({Key? key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<DataLogs> {
  late MqttServerClient _client;
  String _status = "Disconnected";
  List<Map<String, dynamic>> _dataHistory = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _connectToMqtt();
  }

  Future<void> _connectToMqtt() async {
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
        if (!mounted)   return;
        _updateData(payload);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = "Connection failed");
    }
  }

  void _onConnected() {
    if (!mounted) return;
    setState(() => _status = "Connected");
  }

  void _onDisconnected() {
    if (!mounted) return;
    setState(() => _status = "Disconnected");
  }

  void _updateData(String payload) {
    try {
      // final data = jsonDecode(payload) as List<dynamic>;
      final data = jsonDecode(payload) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        // _dataHistory.insert(0, {
        //   'timestamp': data[0],
        //   'acc_x': data[1],
        //   'acc_y': data[2],
        //   'acc_z': data[3],
        //   'gyro_x': data[4],
        //   'gyro_y': data[5],
        //   'gyro_z': data[6],
        //   'activity': data[7],
        // });
        _dataHistory.insert(0, {
          'timestamp': data['timestamp'],
          'acc_x': data['acc_x'],
          'acc_y': data['acc_y'],
          'acc_z': data['acc_z'],
          'gyro_x': data['gyro_x'],
          'gyro_y': data['gyro_y'],
          'gyro_z': data['gyro_z'],
          'activity': data['activity'],
        });

        // Keep only last 100 entries
        if (_dataHistory.length > 100) {
          _dataHistory.removeLast();
        }
      });

      // Auto-scroll to top when new data arrives
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print("Data parse error: $e");
    }
  }

  Widget _buildDataRow(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Timestamp
          SizedBox(
            width: 60,
            child: Text(
              data['timestamp'].toString().split(' ').last,
              style: const TextStyle(fontSize: 12),
            ),
          ),

          // Accelerometer
          _buildSensorChip(
              'A',
              '${data['acc_x'].toStringAsFixed(1)}'
                  '/${data['acc_y'].toStringAsFixed(1)}'
                  '/${data['acc_z'].toStringAsFixed(1)}'),

          // Gyroscope
          _buildSensorChip(
              'G',
              '${data['gyro_x'].toStringAsFixed(1)}'
                  '/${data['gyro_y'].toStringAsFixed(1)}'
                  '/${data['gyro_z'].toStringAsFixed(1)}'),

          // Activity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getActivityColor(data['activity']),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              data['activity'].toString().substring(0, 3).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
      case 'walking':
        return Colors.blue;
      case 'running':
        return Colors.green;
      case 'falling':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(96, 181, 255, 1),
        title: const Text('Sensor Data', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, color: Colors.white),),
        actions: [
          Icon(
            _status == "Connected" ? Icons.wifi : Icons.wifi_off,
            color: _status == "Connected" ? Colors.green : Colors.red,
          ),
        ],
      ),
      body: Column(
        children: [
          // Current Data Display
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text("CURRENT READING",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _dataHistory.isNotEmpty
                    ? _buildDataRow(_dataHistory.first)
                    : _buildDataRow({
                        'timestamp': '--:--:--',
                        'acc_x': 0.0,
                        'acc_y': 0.0,
                        'acc_z': 0.0,
                        'gyro_x': 0.0,
                        'gyro_y': 0.0,
                        'gyro_z': 0.0,
                        'activity': 'waiting'
                      }),
              ],
            ),
          ),

          // Historical Data List
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child:
                Text("HISTORY", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _dataHistory.length,
              itemBuilder: (context, index) {
                return _buildDataRow(_dataHistory[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _client.disconnect();
    _scrollController.dispose();
    super.dispose();
  }
}
