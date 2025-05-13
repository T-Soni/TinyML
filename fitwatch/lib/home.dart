import 'package:fitwatch/activityPage.dart';
import 'package:fitwatch/dataLogs.dart';
import 'package:fitwatch/profilePage.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  int currentPageIndex = 0;
  late MqttServerClient _client;
  String _status = "Disconnected";
  List<Map<String, dynamic>> _dataHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _connectToMqtt();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('sensor_data_history');
    if (savedData != null) {
      setState(() {
        _dataHistory = List<Map<String, dynamic>>.from(
            jsonDecode(savedData).map((e) => Map<String, dynamic>.from(e)));
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sensor_data_history', jsonEncode(_dataHistory));
  }

  Future<void> _connectToMqtt() async {
    _client = MqttServerClient.withPort('192.168.29.16', 'flutter_client', 1883);
    _client.keepAlivePeriod = 30;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;

    try {
      await _client.connect();
      _client.subscribe('wearable/sensor_data', MqttQos.atLeastOnce);
      _client.updates?.listen((messages) {
        final message = messages[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        if (!mounted) return;
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
      final data = jsonDecode(payload) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
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
        _saveData(); // Save to SharedPreferences
      });
    } catch (e) {
      print("Data parse error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          if (!mounted) return;
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Color.fromRGBO(96, 181, 255, 1),
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Data',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.label_important),
            icon: Icon(Icons.label_important_outline),
            label: 'Activity',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person),
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      body:IndexedStack(
        index: currentPageIndex,
        children: [
          DataLogs(dataHistory: _dataHistory, status: _status),
          AnnotateActivity(),
          Profile(),
          
        ],
      ),
          
    );
  }
  @override
  void dispose() {
    _client.disconnect();
    super.dispose();
  }
}