import 'package:fitwatch/utilities/gradientButton.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnnotateActivity extends StatefulWidget {
  final Function(String) onStart;
  final Function() onStop;

  const AnnotateActivity({
    super.key,
    required this.onStart,
    required this.onStop,
  });

  @override
  State<AnnotateActivity> createState() => _AnnotateActivityState();
}

class _AnnotateActivityState extends State<AnnotateActivity> {
  String? _selectedActivity;

  bool _isCollecting = false;

  void _handleActivitySelect(String activity) {
    setState(() {
      _selectedActivity = activity;
    });
    // If already collecting, switch activity immediately
    if (_isCollecting) {
      widget.onStart(activity);
    }
  }

  void _handleStartPressed(BuildContext context) {
    if (_selectedActivity == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Activity Required"),
          content: const Text("Please select an activity before starting."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    } else {
      widget.onStart(_selectedActivity!);
      setState(() => _isCollecting = true);
    }
  }

  void _handleStopPressed() {
    widget.onStop();
    setState(() => _isCollecting = false);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(96, 181, 255, 1),
        title: const Text(
          'Activity',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          // Optional network status icon
          // Icon(
          //   _status == "Connected" ? Icons.wifi : Icons.wifi_off,
          //   color: _status == "Connected" ? Colors.green : Colors.red,
          // ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Activity Buttons
            ..._buildActivityButtons(),
            const SizedBox(height: 30),
            // Collection Status
            _buildCollectionStatus(),
            const SizedBox(height: 20),
            // Start/Stop Buttons
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActivityButtons() {
    final activities = {
      'WALKING': [Colors.blue, const Color.fromARGB(255, 9, 61, 104)],
      'WALKING_UPSTAIRS': [Colors.green, const Color.fromARGB(255, 31, 96, 33)],
      'WALKING_DOWNSTAIRS': [
        Colors.red,
        const Color.fromARGB(255, 131, 29, 22)
      ],
      'SITTING': [Colors.amber, const Color.fromARGB(255, 136, 103, 5)],
      'STANDING': [Colors.orange, const Color.fromARGB(255, 130, 79, 1)],
      'LAYING': [Colors.deepPurple, const Color.fromARGB(255, 52, 23, 102)],
    };

    return activities.entries.map((entry) {
      final isSelected = _selectedActivity == entry.key;
      final isActive = _isCollecting && isSelected;

      return Column(
        children: [
          RaisedGradientButton(
            child: Text(
              entry.key.replaceAll('_', ' '),
              style: const TextStyle(color: Colors.white, fontSize: 25),
            ),
            gradient: LinearGradient(
              colors: isActive
                  ? [Colors.lightBlue, Colors.blue] // Active collection color
                  : isSelected
                      ? [Colors.blue, Colors.blue.shade800] // Selected color
                      : entry.value, // Default color
            ),
            onPressed: () => _handleActivitySelect(entry.key),
          ),
          const SizedBox(height: 10),
        ],
      );
    }).toList();
  }

  Widget _buildCollectionStatus() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isCollecting
          ? Text(
              "Recording: ${_selectedActivity!.replaceAll('_', ' ')}",
              key: ValueKey(_selectedActivity),
              style: const TextStyle(
                color: Colors.green,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildControlButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () => _handleStartPressed(context),
            icon: Icon(
              Icons.play_arrow,
              color: Colors.white,
            ),
            label: const Text("Start", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCollecting
                  ? Colors.grey
                  : const Color.fromRGBO(96, 181, 255, 1),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _isCollecting ? _handleStopPressed : null,
            icon: const Icon(Icons.stop, color: Colors.white),
            label: const Text("Stop", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: !_isCollecting
                  ? Colors.grey
                  : const Color.fromRGBO(96, 181, 255, 1),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

Widget userData(String key, String value) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
