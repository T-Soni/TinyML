import 'package:fitwatch/widgets/gradientButton.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitwatch/globals.dart' as globals;

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
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                // const Color.fromARGB(255, 132, 169, 155),
                Colors.white10,
                Color.fromRGBO(224, 224, 224, 1), // white
              ],
              stops: [0.09, 0.55],
            ),
          ),
        ),
        Scaffold(
          // backgroundColor: const Color.fromRGBO(224, 224, 224, 1),
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Human Activity Monitoring and Recognition",
                    style: TextStyle(
                        fontFamily: 'Merriweather',
                        fontSize: 35,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  // Text(
                  //   (!_isCollecting) ? 'Select an activity' : '',
                  //   style: TextStyle(fontSize: 15, color: Colors.black54),
                  // ),
                  // Activity Buttons
                  ..._buildActivityButtons(),
                  const SizedBox(height: 0),
                  // Collection Status
                  _buildCollectionStatus(),
                  const SizedBox(height: 8),
                  // Start/Stop Buttons
                  _buildControlButtons(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActivityButtons() {
    final activities = {
      'WALKING': [Colors.blue, const Color.fromARGB(255, 154, 192, 223)],
      'WALKING_UPSTAIRS': [
        const Color.fromARGB(255, 112, 198, 86),
        const Color.fromARGB(255, 174, 220, 176)
      ],
      'WALKING_DOWNSTAIRS': [
        Colors.red,
        const Color.fromARGB(255, 211, 156, 152)
      ],
      'SITTING': [Colors.amber, const Color.fromARGB(255, 229, 213, 167)],
      'STANDING': [Colors.orange, const Color.fromARGB(255, 221, 193, 151)],
      'LAYING': [
        const Color.fromARGB(255, 109, 66, 183),
        const Color.fromARGB(255, 204, 182, 241)
      ],
    };

    List<Widget> buttonRows = [];
    List<Widget> currentRow = [];

    activities.entries.toList().asMap().forEach((index, entry) {
      final isSelected = _selectedActivity == entry.key;
      final isActive = _isCollecting && isSelected;

      currentRow.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: RaisedGradientButton(
              isActive: isActive,
              isSelected: isSelected,
              gradient: LinearGradient(
                colors:
                    // isActive
                    //     ? [
                    //         const Color.fromARGB(255, 3, 3, 93),
                    //         const Color.fromARGB(255, 63, 91, 202)
                    //       ]
                    //     : isSelected
                    //         ? [
                    //             const Color.fromARGB(255, 3, 3, 93),
                    //             const Color.fromARGB(255, 63, 91, 202)
                    //           ]
                    // :
                    entry.value,
              ),
              onPressed: () => _handleActivitySelect(entry.key),
              child: Text(
                entry.key.replaceAll('_', ' '),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      );

      // If 2 buttons are added or it's the last item, create a row
      if (currentRow.length == 2 || index == activities.length - 1) {
        buttonRows.add(Row(children: currentRow));
        buttonRows.add(const SizedBox(height: 10)); // Add spacing between rows
        currentRow = [];
      }
    });

    return buttonRows;
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            )
          : const Text(
              'Select an activity',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
                // fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildControlButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              if (globals.isConnected || globals.isConnectedBle) {
                if (_isCollecting)
                  _handleStopPressed();
                else
                  _handleStartPressed(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Waiting for the connection...")),
                );
              }
            },
            icon: Icon(
              _isCollecting ? Icons.stop : Icons.play_arrow,
              color: Colors.white,
            ),
            label: Text(
              _isCollecting ? "Stop" : "Start",
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 5,
              backgroundColor: _isCollecting ? Colors.red : Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            ),
          ),
          // const SizedBox(width: 10),
          // ElevatedButton.icon(
          //   onPressed: _isCollecting ? _handleStopPressed : null,
          //   icon: const Icon(Icons.stop, color: Colors.white),
          //   label: const Text("Stop", style: TextStyle(color: Colors.white)),
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: !_isCollecting
          //         ? Colors.grey
          //         : const Color.fromRGBO(96, 181, 255, 1),
          //     padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          //   ),
          // ),
        ],
      ),
    );
  }
}
