import 'dart:async';
import 'dart:io';

import 'package:fitwatch/activityPage.dart';
import 'package:fitwatch/analysis.dart';
import 'package:fitwatch/dataLogs.dart';
import 'package:fitwatch/profilePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

import 'package:fitwatch/globals.dart' as globals;

enum ConnectionType { bluetooth, mqtt }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // late BuildContext _scaffoldContext;
  int currentPageIndex = 0;
  late MqttServerClient _client;
  String _status = "Disconnected";
  List<Map<String, dynamic>> _dataHistory = [];
  ConnectionType? selectedConnection;

  String? _currentActivity;
  bool _isCollecting = false;

  final List<Map<String, dynamic>> _newDataBuffer = [];

  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _mqttSubscription;

  List<ScanResult> _recordList = [];
  StreamSubscription? _btStateSubscription;
  bool _isScanning = false;
  PersistentBottomSheetController? _bottomSheetController;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    // _connectToMqtt();
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

  Future<void> startScanning() async {
    try {
      _recordList.clear();
      _isScanning = true;
      setState(() {});

      await FlutterBluePlus.stopScan();
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 30),
        androidUsesFineLocation: true,
      );

      FlutterBluePlus.scanResults.listen((results) {
        bool updated = false;
        for (var result in results) {
          if (!_recordList
              .any((r) => r.device.remoteId == result.device.remoteId)) {
            _recordList.add(result);
            updated = true;
            print('Found ${result.device.advName}');
          }
        }
        if (updated) {
          setState(() {
            if (_bottomSheetController == null) {
              _bottomSheetController = _showDeviceListSheet();
            }
          });
        }
      });
    } catch (e) {
      print("Scan error: $e");
    } finally {
      _isScanning = false;
      setState(() {});
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    }
    return true;
  }

  void _connectViaBluetooth() async {
    // Initialize Bluetooth and check hardware support
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return;
    }

    //Request location permissions
    bool permissionGranted = await _requestPermissions();
    if (!permissionGranted) return;

    //Check if location services are enabled
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      //show dialog and redirect to location settings
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text("Location Services Off"),
                content: Text(
                    "Please tuen on location services (GPS) to scan Bluetooth devices."),
                actions: [
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await Geolocator
                          .openLocationSettings(); //opens device settings
                    },
                    child: Text("Open Settings"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("Cancel"),
                  ),
                ],
              ));
      return;
    }

// Handle Bluetooth state changes
// note: if you have permissions issues you will get stuck at BluetoothAdapterState.unauthorized
    _btStateSubscription = FlutterBluePlus.adapterState.listen((state) async {
      if (state == BluetoothAdapterState.on) {
        // Ready to scan/connect
        print("Bluetooth is ON");
        await startScanning();
      } else if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      } else {
        // Handle disabled state
        print("Bluetooth is OFF");
      }
    });

// cancel to prevent duplicate listeners
    // subscription.cancel();
  }



  Future<void> _discoverServices(BluetoothDevice device) async {
  try {
    List<BluetoothService> services = await device.discoverServices(); //this returns a list of available GATT services
    
    // Find the specific service (FE00)
    BluetoothService? targetService;
    try {
      targetService = services.firstWhere(
        (service) => service.serviceUuid.toString().toUpperCase() == 'FE00'
      );
    } catch (e) {
      print('FE00 service not found');
      return;
    }

    print("Found service: ${targetService.serviceUuid}");

    // Find the specific characteristic (FE01)
    BluetoothCharacteristic? targetChar;
    try {
      targetChar = targetService.characteristics.firstWhere(
        (c) => c.characteristicUuid.toString().toUpperCase() == 'FE01'
      );
    } catch (e) {
      print('FE01 characteristic not found');
      return;
    }

    print("Found characteristic: ${targetChar.characteristicUuid}");

    //checks if characteristic supports read
    if (targetChar.properties.read) {
      //reads the data (List<int>, i.e. raw bytes)
      List<int> value = await targetChar.read();
      
      //converts each byte into a 2-digit hex string and joins them
      String hexString = value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
      print('Hex data: $hexString');
      
      //Converts the bytes to a UTF-8 string, assuming it is JSON
      String jsonString = String.fromCharCodes(value);
      print('Raw JSON string: $jsonString');
      
      //try to parse the string into a JSON object
      try {
        dynamic jsonData = jsonDecode(jsonString);
        print('Decoded JSON: $jsonData');
      } catch (e) {
        print('Error parsing JSON: $e');
      }
      
      //Check if the characteristic supports notifications
      if (targetChar.properties.notify) {
        // Subscribes to real-time updates when new data arrives
        targetChar.onValueReceived.listen((value) {
          String newData = String.fromCharCodes(value);
          print('New notification data: $newData');

          try {
            dynamic jsonData = jsonDecode(newData);
            print('Decoded JSON from notification : $jsonData');
          }catch(e){
            print('Error parsing JSON from notifications: $e');
          }
        });
        await targetChar.setNotifyValue(true);
      }
    } else {
      print('Characteristic is not readable');
    }
    
  } catch (e) {
    print('Error discovering services: $e');
  }
}
//Tap on any device -> stop the ongoing scanning process and then connect to the device
  Future<void> _connectToDevice(BluetoothDevice device) async {
    FlutterBluePlus.stopScan();
    
    try{
      await device.connect();
      await device.requestMtu(256);
      device.connectionState.listen((BluetoothConnectionState state){
      if(state == BluetoothConnectionState.connected) {
        print("Device is connected!");
        _discoverServices(device);
      }
      else{
        print("Device is not connected.");
      }
    });
    }catch (e) {
      print("Error connecting to device: $e");
    }
    

  }

  Future<void> _connectToMqtt() async {
    setState(() {
      globals.isConnecting = true;
      _status = "Connecting...";
    });
    //Replace IP_ADDRESS with the actual MQTT broker IP

    _client =
        MqttServerClient.withPort('192.168.29.16', 'flutter_client', 1883);
    // MqttServerClient.withPort('192.168.0.141', 'flutter_client', 1883);

    _client.keepAlivePeriod = 30;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;

    try {
      await _client.connect();
      _client.subscribe('wearable/sensor_data', MqttQos.atLeastOnce);
      // _client.subscribe('sensor/esp', MqttQos.atLeastOnce);
      _client.updates?.listen((messages) {
        final message = messages[0].payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(message.payload.message);
        if (!mounted) return;
        _updateData(payload);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = "Connection failed";
        globals.isConnecting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('MQTT Connection Failed')),
      );
      return;
    }
  }

  void _onConnected() {
    if (!mounted) return;
    setState(() {
      _status = "Connected";
      globals.isConnecting = false;
      globals.isConnected = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("MQTT Connected")),
    );
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
    // _scaffoldContext = context;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(96, 181, 255, 1),
        actions: [
          PopupMenuButton<ConnectionType>(
              initialValue: selectedConnection,
              onSelected: (ConnectionType connection) {
                setState(() {
                  selectedConnection = connection;
                });
                if (connection == ConnectionType.mqtt) {
                  //trigger MQTT connection
                  _connectToMqtt();
                }
                if (connection == ConnectionType.bluetooth) {
                  _connectViaBluetooth();
                }
              },
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<ConnectionType>>[
                    const PopupMenuItem<ConnectionType>(
                      value: ConnectionType.mqtt,
                      child: Text('Connect via MQTT'),
                    ),
                    const PopupMenuItem<ConnectionType>(
                      value: ConnectionType.bluetooth,
                      child: Text("Connect via Bluetooth"),
                    )
                  ])
        ],
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
      body: Column(
        children: [
          if (globals.isConnecting || _isScanning)
            LinearProgressIndicator(
              color: Colors.white,
            ),
          Expanded(
            child: IndexedStack(
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
          ),
        ],
      ),
    );
  }

  PersistentBottomSheetController? _showDeviceListSheet() {
    return _scaffoldKey.currentState?.showBottomSheet(
      elevation: 10,
      (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Available Devices', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Expanded(
              child: _recordList.isEmpty
                  ? Center(child: Text("No devices found"))
                  : ListView.builder(
                      itemCount: _recordList.length,
                      itemBuilder: (context, index) {
                        final device = _recordList[index].device;
                        return Card(
                          child: ListTile(
                            title: Text(device.advName.isNotEmpty
                                ? device.advName
                                : 'Unknown Device'),
                            subtitle: Text(device.remoteId.toString()),
                            onTap: () async {
                              await _connectToDevice(device);
                              if (_bottomSheetController != null) {
                                _bottomSheetController!.close();
                                _bottomSheetController = null;
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bottomSheetController?.close(); // Important!
    _btStateSubscription?.cancel();
    _mqttSubscription?.cancel();
    _client.disconnect();
    super.dispose();
  }
}
