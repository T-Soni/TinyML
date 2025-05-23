// _client = MqttServerClient.withPort('192.168.29.16', 'flutter_client', 1883);
// _client.subscribe('wearable/sensor_data', MqttQos.atLeastOnce);
import 'dart:async';

import 'package:fitwatch/activityPage.dart';
import 'package:fitwatch/analysis.dart';
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

  String? _currentActivity;
  bool _isCollecting = false;
  final List<Map<String, dynamic>> _newDataBuffer = [];

  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _mqttSubscription;

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
    //Replace IP_ADDRESS with the actual MQTT broker IP

    _client =
        MqttServerClient.withPort('192.168.0.141', 'flutter_client', 1883);

    _client.keepAlivePeriod = 30;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;

    try {
      await _client.connect();

      _client.subscribe('sensor/esp', MqttQos.atLeastOnce);
      _client.updates?.listen((messages) {
        final message = messages[0].payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(message.payload.message);
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

  void _startCollection(String activity) {
    setState(() {
      _currentActivity = activity;
      _isCollecting = true;
    });
  }

  void _stopCollection() {
    setState(() {
      _isCollecting = false;
      // Merge buffer with main history
      _dataHistory.insertAll(0, _newDataBuffer);
      _newDataBuffer.clear();
      _saveData();
    });
  }

  void _updateData(String payload) {
    if (!_isCollecting) return; // Critical: Ignore all data when not collecting

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _newDataBuffer.insert(0, {
          ...data,
          'activity': _currentActivity!,
        });
      });
    } catch (e) {
      print("Data parse error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    print('ANALYSIS SCREEN DATA CHECK:');
    print(
        'Total points: ${_isCollecting ? _newDataBuffer.length + _dataHistory.length : _dataHistory.length}');
    if (_dataHistory.isNotEmpty) {
      print('First point acc_x: ${_dataHistory.first['acc_X']}');
    }
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(96, 181, 255, 1),
      ),
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
            selectedIcon: Icon(
              Icons.insights,
              color: Colors.white,
            ),
            icon: Icon(Icons.insights_outlined),
            label: 'Data',
          ),
          NavigationDestination(
            selectedIcon: Icon(
              Icons.label_important,
              color: Colors.white,
            ),
            icon: Icon(Icons.label_important_outline),
            label: 'Activity',
          ),
          NavigationDestination(
              selectedIcon: Icon(
                Icons.analytics,
                color: Colors.white,
              ),
              icon: Icon(Icons.analytics_outlined),
              label: 'Analysis'),
          NavigationDestination(
            selectedIcon: Icon(
              Icons.person,
              color: Colors.white,
            ),
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      body: IndexedStack(
        index: currentPageIndex,
        children: [
          DataLogs(
            dataHistory: _isCollecting
                ? [..._newDataBuffer, ..._dataHistory]
                : _dataHistory,
            status: _status,
          ),
          AnnotateActivity(
            onStart: _startCollection,
            onStop: _stopCollection,
          ),
          AnalysisScreen(
            dataHistory: _isCollecting
                ? [..._newDataBuffer, ..._dataHistory]
                : _dataHistory,
            status: _status,
          ),
          Profile(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mqttSubscription?.cancel();
    _client.disconnect();
    super.dispose();
  }
}
