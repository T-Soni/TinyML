import 'dart:async';

import 'package:fitwatch/sensorChart.dart';
import 'package:fitwatch/utilities/databaseHelper.dart';
import 'package:fitwatch/utilities/sensorDataRepository.dart';
import 'package:fitwatch/widgets/dropdownMenu.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';

late int dataPointsLength1;

class AnalysisScreen extends StatefulWidget {
  final String status;

  const AnalysisScreen({
    // required this.dataHistory,
    required this.status,
    super.key,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  List<Map<String, dynamic>> _dataHistory = [];
  bool _isLoading = true;

  late StreamSubscription _dataSubscription;

  final _sensorRepo = SensorDataRepository(DatabaseHelper.instance);
  int selectedIndex = 0; // 0 = Accelerometer, 1 = Gyrometer
  final int _displayPoints = 50;

  @override
  void initState() {
    super.initState();
    // _loadData();
    // _setupDataStream();
  }

  void _setupDataStream() {
    _dataSubscription = _sensorRepo.getRealtimeDataStream().listen((data) {
      if (mounted) {
        setState(() {
          _dataHistory = data;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _dataSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final logs = await _sensorRepo.getRawData(limit: 100); //check
    setState(() {
      _dataHistory = logs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> accX = [];
    final List<FlSpot> accY = [];
    final List<FlSpot> accZ = [];
    final List<FlSpot> gyroX = [];
    final List<FlSpot> gyroY = [];
    final List<FlSpot> gyroZ = [];
    // if (widget.dataHistory.isNotEmpty && widget.dataHistory.length >= _displayPoints) {
    double maxY = -double.infinity;
    double minY = double.infinity;
    double gmaxY = -double.infinity;
    double gminY = double.infinity;
    late double currMaxA;
    late double currMaxG;
    late double currMinA;
    late double currMinG;
    // double maxY = 10, minY = -10; // Default ranges
    // double gmaxY = 10, gminY = -10;

    int dataPointsLength =
        (50 < _dataHistory.length) ? 50 : _dataHistory.length;
    // int dataPointsLength =
    //     (50 < widget.dataHistory.length) ? 50 : widget.dataHistory.length;
    dataPointsLength1 = _dataHistory.length;
    // dataPointsLength1 = widget.dataHistory.length;
    if (dataPointsLength == 0) {
      return Material(
        child: Expanded(
            child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Empty Data Set',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              Text('Start an activity now!')
            ],
          ),
        )),
      );
    }
    // Display latest entries in reverse
    // for (int i = 50; i >= 0; i--) {
    for (int i = dataPointsLength - 1; i >= 0; i--) {
      final data = _dataHistory[i];
      // final data = widget.dataHistory[i];
      final x = _parseDouble(data['acc_X']);
      final y = _parseDouble(data['acc_Y']);
      final z = _parseDouble(data['acc_Z']);
      final gx = _parseDouble(data['gyro_X']);
      final gy = _parseDouble(data['gyro_Y']);
      final gz = _parseDouble(data['gyro_Z']);

      accX.add(FlSpot(50 - i.toDouble(), x));
      accY.add(FlSpot(50 - i.toDouble(), y));
      accZ.add(FlSpot(50 - i.toDouble(), z));

      gyroX.add(FlSpot(50 - i.toDouble(), gx));
      gyroY.add(FlSpot(50 - i.toDouble(), gy));
      gyroZ.add(FlSpot(50 - i.toDouble(), gz));

      currMaxA = max(x, max(y, x));
      currMinA = min(x, min(y, z));
      currMaxG = max(gx, max(gy, gz));
      currMinG = min(gx, min(gy, gz));
      maxY = currMaxA > maxY ? currMaxA + (currMaxA - currMinA) / 20 : maxY;
      minY = currMinA < minY ? currMinA - (currMaxA - currMinA) / 20 : minY;
      gmaxY = currMaxG > gmaxY ? currMaxG + (currMaxG - currMinG) / 20 : gmaxY;
      gminY = currMinG < gminY ? currMinG - (currMaxG - currMinG) / 20 : gminY;
      // maxY = x > maxY ? x : maxY;
      // minY = x < minY ? x : minY;
      // gmaxY = gx > gmaxY ? gx : gmaxY;
      // gminY = gx < gminY ? gx : gminY;
    }

    maxY += 5;
    minY -= 5;
    gmaxY += 5;
    gminY -= 5;

    return (_isLoading)
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color.fromARGB(255, 132, 169, 155),
                      Color.fromRGBO(224, 224, 224, 1), // white
                    ],
                    stops: [0.09, 0.55],
                  ),
                ),
              ),
              Scaffold(
                // backgroundColor: const Color.fromARGB(255, 209, 225, 215),
                backgroundColor: Colors.transparent,
                // appBar: AppBar(title: const Text('Analysis')),
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Debug info
                        // Padding(
                        //   padding: const EdgeInsets.all(16.0),
                        //   child: Column(
                        //     children: [
                        //       Text('Total Points: ${dataHistory.length}'),
                        //       Text('Y-Range: ${minY.toStringAsFixed(1)} to ${maxY.toStringAsFixed(1)}'),
                        //       Text('First X value: ${accX.isNotEmpty ? accX.first.y : "N/A"}'),
                        //     ],
                        //   ),
                        // ),

                        const SizedBox(height: 16),
                        ToggleButtons(
                          isSelected: [selectedIndex == 0, selectedIndex == 1],
                          onPressed: (int index) {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          borderColor: Colors.black54,
                          selectedBorderColor: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                          selectedColor: const Color.fromARGB(255, 65, 64, 64),
                          fillColor: Colors.white70,
                          // fillColor: const Color.fromARGB(255, 132, 169, 155),
                          color: Colors.white,
                          constraints: const BoxConstraints(
                              minWidth: 150, minHeight: 40),
                          children: const [
                            Text(
                              "Accelerometer",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text("Gyroscope",
                                style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),

                        // Padding(
                        //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        // Card(
                        //   elevation: 4,
                        //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        //   child: Padding(
                        //     padding: const EdgeInsets.all(16.0),
                        //     child: SizedBox(
                        //       height: 300,
                        //       child: LineChart(
                        //         LineChartData(
                        //           minX: 0,
                        //           maxX: 50,
                        //           minY: minY,
                        //           maxY: maxY,
                        //           titlesData: const FlTitlesData(
                        //             leftTitles: AxisTitles(
                        //               sideTitles: SideTitles(showTitles: false),
                        //             ),
                        //             bottomTitles: AxisTitles(
                        //               sideTitles: SideTitles(showTitles: true),
                        //             ),
                        //           ),
                        //           gridData: const FlGridData(show: true),
                        //           borderData: FlBorderData(
                        //             show: true,
                        //             border: Border.all(color: Colors.grey),
                        //           ),
                        //           lineBarsData: [
                        //             _createLineData(accX, Colors.blue),
                        //             _createLineData(accY, Colors.orange),
                        //             _createLineData(accZ, Colors.green),
                        //           ],
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("${dataPointsLength1}"),
                            Container(
                              height: 10,
                              width: 10,
                              decoration: BoxDecoration(
                                  color: Colors.blue,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1,
                                  )),
                            ),
                            const SizedBox(width: 8),
                            const Text("X"),
                            const SizedBox(width: 8),
                            Container(
                              height: 10,
                              width: 10,
                              decoration: BoxDecoration(
                                  color: Colors.orange,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1,
                                  )),
                            ),
                            const SizedBox(width: 8),
                            const Text("Y"),
                            const SizedBox(width: 8),
                            Container(
                              height: 10,
                              width: 10,
                              decoration: BoxDecoration(
                                  color: Colors.green,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1,
                                  )),
                            ),
                            const SizedBox(width: 8),
                            const Text("Z"),
                          ],
                        ),
                        if (selectedIndex == 0)
                          SensorChart(
                            xData: accX,
                            yData: accY,
                            zData: accZ,
                            minY: minY,
                            maxY: maxY,
                            showX: true,
                            showY: true,
                            showZ: true,
                          )
                        else
                          SensorChart(
                            xData: gyroX,
                            yData: gyroY,
                            zData: gyroZ,
                            minY: gminY,
                            maxY: gmaxY,
                            showX: true,
                            showY: true,
                            showZ: true,
                          ),

                        // ),
                        SizedBox(
                          height: 10,
                        ),
                        SizedBox(height: 20),

                        _buildActivityTimeAnalysisChart(
                            _calculateActivityDurations()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
  }

  LineChartBarData _createLineData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: color,
      barWidth: 1.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  double _parseDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  Map<String, Duration> _calculateActivityDurations() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final durations = <String, Duration>{
      "walking": Duration.zero,
      "walking_upstairs": Duration.zero,
      "walking_downstairs": Duration.zero,
      "sitting": Duration.zero,
      "standing": Duration.zero,
      "laying": Duration.zero,
    };

    // Filter and sort today's data
    final todayData = _dataHistory.where((entry) {
      // final todayData = widget.dataHistory.where((entry) {
      // final timestamp = DateTime.fromMillisecondsSinceEpoch(entry['timestamp']);
      final timestamp = DateTime.parse(entry['timestamp']);
      return timestamp.isAfter(todayStart);
    }).toList()
      ..sort((a, b) => DateTime.parse(a['timestamp'])
          .compareTo(DateTime.parse(b['timestamp'])));
    // ..sort((a, b) => DateTime.fromMillisecondsSinceEpoch(a['timestamp'])
    //     .compareTo(DateTime.fromMillisecondsSinceEpoch(b['timestamp'])));

    String? currentActivity;
    DateTime? activityStartTime;

    for (final entry in todayData) {
      final entryActivity = entry['activity']?.toString().toLowerCase();
      if (!durations.containsKey(entryActivity)) continue;

      if (currentActivity != entryActivity) {
        if (currentActivity != null && activityStartTime != null) {
          final duration =
              DateTime.parse(entry['timestamp']).difference(activityStartTime);
          // final duration =
          //     DateTime.fromMillisecondsSinceEpoch(entry['timestamp'])
          //         .difference(activityStartTime!);

          if (duration.inSeconds > 0) {
            durations[currentActivity] = durations[currentActivity]! + duration;
          }
        }
        currentActivity = entryActivity;
        activityStartTime =
            // DateTime.fromMillisecondsSinceEpoch(entry['timestamp']);
            activityStartTime = DateTime.parse(entry['timestamp']);
      }
    }

    return durations;
  }

  Color _getActivityColor(String activity) {
    switch (activity) {
      case "walking":
        return Colors.blue;
      case "walking_upstairs":
        return Colors.green;
      case "walking_downstairs":
        return Colors.red;
      case "sitting":
        return Colors.amber;
      case "standing":
        return Colors.orange;
      case "laying":
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActivityTimeAnalysisChart(
      Map<String, Duration> activityDurations) {
    const allActivities = [
      "walking",
      "walking_upstairs",
      "walking_downstairs",
      "sitting",
      "standing",
      "laying"
    ];

    final maxSeconds = activityDurations.values.fold<double>(
        0, (max, d) => d.inSeconds > max ? d.inSeconds.toDouble() : max);

    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activity Analysis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownMenuWidget(),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    minY: 0,
                    maxY: maxSeconds * 1.2,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final activity = allActivities[group.x];
                          final duration = Duration(seconds: rod.toY.round());
                          String timeText;
                          if (duration.inHours > 0) {
                            timeText =
                                '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
                          } else if (duration.inMinutes > 0) {
                            timeText =
                                '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
                          } else {
                            timeText = '${duration.inSeconds}s';
                          }
                          return BarTooltipItem(
                            timeText,
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: '\n${activity.replaceAll('_', ' ')}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          );
                        },
                        // tooltipBgColor: Colors.black87,
                        tooltipMargin: 8,
                        tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        tooltipBorder: BorderSide.none,
                        direction: TooltipDirection.top,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final activity = allActivities[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                activity
                                    .split('_')
                                    .map((s) => s[0].toUpperCase())
                                    .join(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                          reservedSize: 36,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: maxSeconds > 60
                              ? (maxSeconds / 5).roundToDouble()
                              : maxSeconds > 10
                                  ? 10
                                  : 1,
                          getTitlesWidget: (value, meta) {
                            final duration = Duration(seconds: value.toInt());
                            if (duration.inHours > 0) {
                              return Text('${duration.inHours}h',
                                  style: const TextStyle(fontSize: 10));
                            } else if (duration.inMinutes > 0) {
                              return Text('${duration.inMinutes}m',
                                  style: const TextStyle(fontSize: 10));
                            } else {
                              return Text('${duration.inSeconds}s',
                                  style: const TextStyle(fontSize: 10));
                            }
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                        // show: false
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            )),
                    borderData:
                        FlBorderData(show: false), // remove chart border
                    barGroups: allActivities.map((activity) {
                      final seconds =
                          activityDurations[activity]?.inSeconds.toDouble() ??
                              0;
                      final isCurrent = activity ==
                          'running'; // or any logic to highlight one bar
                      return BarChartGroupData(
                        x: allActivities.indexOf(activity),
                        barRods: [
                          BarChartRodData(
                            toY: seconds,
                            width: 27,
                            borderRadius: BorderRadius.circular(6),
                            color: isCurrent
                                ? Colors.orange
                                : Colors.grey.shade300,
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxSeconds * 1.2,
                              color: Colors.transparent,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
