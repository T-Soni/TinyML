import 'dart:async';

import 'package:fitwatch/utilities/axis_tick_helper.dart';
import 'package:fitwatch/sensorChart.dart';
import 'package:fitwatch/utilities/databaseHelper.dart';
import 'package:fitwatch/utilities/sensorDataRepository.dart';
import 'package:fitwatch/widgets/ColorPalette.dart';
import 'package:fitwatch/widgets/activity_chart_widget.dart';
import 'package:fitwatch/widgets/dropdownMenu.dart';
import 'package:fitwatch/widgets/groupActivityChart.dart' hide allActivities;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:fitwatch/utilities/ActivityColors.dart';

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
  List<Map<String, dynamic>> _liveWindow = [];
  bool _isLoading = true;
  late Timer _chartUpdateTimer;

  late StreamSubscription _dataSubscription;
  late Future<Map<String, Duration>> todayDurationsFuture;
  late Future<Map<String, Map<String, int>>> weeklySummary;
  late Future<Map<String, Map<String, int>>> last4WeeksSummary;
  DateTime? _lastProcessedTimestamp = null;
  final int chartUpdateIntervalSeconds = 5;

  final _sensorRepo = SensorDataRepository();
  // final _sensorRepo = SensorDataRepository(DatabaseHelper.instance);
  int selectedIndex = 0; // 0 = Accelerometer, 1 = Gyroscope
  final int _displayPoints = 50;

  String selectedAnalysis = 'Today';

  late ValueNotifier<Map<String, Duration>> activityDurationsNotifier;

  void _onDropdownChanged(String newValue) {
    setState(() {
      selectedAnalysis = newValue;
      //filter data based on selectedAnalysis
    });
  }

  @override
  void initState() {
    _sensorRepo.printAllTableContents();
    weeklySummary = _sensorRepo.getRolling7DaysActivitySummary();
    last4WeeksSummary = _sensorRepo.getLast4WeeksActivitySummary();
    super.initState();
    activityDurationsNotifier = ValueNotifier({});
    _setupLiveWindow();

    _initializeLastProcessedTimestamp().then((_) async {
      final initialDurations = await _sensorRepo.getTodayActivityDuration();
      activityDurationsNotifier.value = initialDurations;

      // Start the periodic updates after the initial DB load
      _chartUpdateTimer = Timer.periodic(
          Duration(seconds: chartUpdateIntervalSeconds),
          (_) => _updateActivityDurations());
    });

    // todayDurationsFuture = _sensorRepo.getTodayActivityDuration();
    //Start periodic timer for chart
    // _chartUpdateTimer =
    //     Timer.periodic(Duration(seconds: chartUpdateIntervalSeconds), (_) {
    //   setState(() {
    //     todayDurationsFuture = _updateActivityDurations();
    //   });
    // });
  }

  Future<void> _updateActivityDurations() async {
    // Future<Map<String, Duration>> _updateActivityDurations() async {
    final newEntries = _liveWindow.where((entry) {
      final ts = DateTime.parse(entry['timestamp']);
      return _lastProcessedTimestamp == null ||
          ts.isAfter(_lastProcessedTimestamp!);
    }).toList();

    if (newEntries.isEmpty) return;
    // if (newEntries.isEmpty) return todayDurationsFuture;
    // final durations = await todayDurationsFuture;
    final durations =
        Map<String, Duration>.from(activityDurationsNotifier.value);
    //update durations with new entries only
    const gapThreshold = Duration(seconds: 2); // treat >2s as a break

    String? currentActivity;
    DateTime? segmentStartTime;
    DateTime? lastTimestamp;

    for (final entry in newEntries) {
      final entryActivity = entry['activity']?.toString().toLowerCase();
      if (!durations.containsKey(entryActivity)) continue;

      final entryTime = DateTime.parse(entry['timestamp'].toString());

      if (currentActivity == null) {
        // Start first segment
        currentActivity = entryActivity;
        segmentStartTime = entryTime;
      } else if (entryActivity != currentActivity ||
          (lastTimestamp != null &&
              entryTime.difference(lastTimestamp) > gapThreshold)) {
        // Activity changed or gap detected, close previous segment
        if (segmentStartTime != null && lastTimestamp != null) {
          final duration = lastTimestamp.difference(segmentStartTime);
          if (duration.inSeconds > 0) {
            durations[currentActivity] = durations[currentActivity]! + duration;
          }
        }
        // Start new segment
        currentActivity = entryActivity;
        segmentStartTime = entryTime;
      }
      lastTimestamp = entryTime;
    }
    // Add last segment if any
    if (currentActivity != null &&
        segmentStartTime != null &&
        lastTimestamp != null) {
      final duration = lastTimestamp.difference(segmentStartTime);
      if (duration.inSeconds > 0) {
        durations[currentActivity] = durations[currentActivity]! + duration;
      }
    }

    //update the last processes timestamp
    _lastProcessedTimestamp = DateTime.parse(newEntries.last['timestamp']);
    // return durations;
    activityDurationsNotifier.value = durations;
  }

  Future<void> _initializeLastProcessedTimestamp() async {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    // Query for the latest rae_logs entry after midnight
    final db = await _sensorRepo.dbHelper.database;
    final result = await db.query(
      'raw_logs',
      where: 'timestamp >= ?',
      whereArgs: [todayMidnight.toIso8601String()],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      // Parse the timestamp from the latest entry
      _lastProcessedTimestamp =
          DateTime.parse(result.first['timestamp'] as String);
    } else {
      // No data after midnight, set to today midnight
      _lastProcessedTimestamp = todayMidnight;
    }
    print("_lastProcessedTimestamp initialized to: $_lastProcessedTimestamp");
  }

// insert last 50 points if no live data
  Future<void> _loadLastStoredData() async {
    final lastData = await _sensorRepo.getRawData(limit: _displayPoints);
    if (mounted) {
      setState(() {
        _liveWindow = lastData.reversed.toList(); //oldest to newest
        _isLoading = false;
      });
    }
  }

  void _setupLiveWindow() {
    _dataSubscription = _sensorRepo.getRealtimeDataStream().listen((data) {
      if (mounted && data.isNotEmpty) {
        setState(() {
          // // Push the latest reading to the window
          // _liveWindow.add(data.first);
          // // Keep only the last 50 readings
          // if (_liveWindow.length > _displayPoints) {
          //   _liveWindow.removeAt(0);
          // }
          // Always keep the latest 50 points, oldest to newest
          // _liveWindow = data.reversed
          //     .take(_displayPoints)
          //     .toList()
          //     .reversed
          //     .toList()
          //     .reversed
          //     .toList();
          _liveWindow = data.take(_displayPoints).toList().reversed.toList();
          // print('new data received' + _liveWindow.last.toString());
          _isLoading = false;
        });
      }
    });
    // if no live data after a short delay, load last stored data
    Future.delayed(const Duration(seconds: 2), () {
      if (_liveWindow.isEmpty && mounted) {
        _loadLastStoredData();
      }
    });
  }

  @override
  void dispose() {
    _dataSubscription.cancel();
    _chartUpdateTimer.cancel();
    activityDurationsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> accX = [];
    final List<FlSpot> accY = [];
    final List<FlSpot> accZ = [];
    final List<FlSpot> gyroX = [];
    final List<FlSpot> gyroY = [];
    final List<FlSpot> gyroZ = [];
    double maxY = -double.infinity;
    double minY = double.infinity;
    double gmaxY = -double.infinity;
    double gminY = double.infinity;
    late double currMaxA;
    late double currMaxG;
    late double currMinA;
    late double currMinG;

    int dataPointsLength = _liveWindow.length;

    if (dataPointsLength == 0) {
      return Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  // Color.fromARGB(255, 132, 169, 155),
                  Colors.white10,
                  Color.fromRGBO(224, 224, 224, 1),
                ],
                stops: [0.09, 0.55],
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'No live sensor data received.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                  Text('Start an activity or check BLE connection.'),
                ],
              ),
            ),
          )
        ],
      );
    }
    //check
    final int startIdx = dataPointsLength > _displayPoints
        ? dataPointsLength - _displayPoints
        : 0;
    //*check
    for (int i = 0; i < dataPointsLength; i++) {
      final data = _liveWindow[i];
      //check
      final spotIdx = i - startIdx;
      //*check
      final x = _parseDouble(data['acc_x']);
      final y = _parseDouble(data['acc_y']);
      final z = _parseDouble(data['acc_z']);
      final gx = _parseDouble(data['gyro_x']);
      final gy = _parseDouble(data['gyro_y']);
      final gz = _parseDouble(data['gyro_z']);
      accX.add(FlSpot(spotIdx.toDouble(), x));
      accY.add(FlSpot(spotIdx.toDouble(), y));
      accZ.add(FlSpot(spotIdx.toDouble(), z));
      gyroX.add(FlSpot(spotIdx.toDouble(), gx));
      gyroY.add(FlSpot(spotIdx.toDouble(), gy));
      gyroZ.add(FlSpot(spotIdx.toDouble(), gz));
      // accX.add(FlSpot(i.toDouble(), x));
      // accY.add(FlSpot(i.toDouble(), y));
      // accZ.add(FlSpot(i.toDouble(), z));
      // gyroX.add(FlSpot(i.toDouble(), gx));
      // gyroY.add(FlSpot(i.toDouble(), gy));
      // gyroZ.add(FlSpot(i.toDouble(), gz));
      currMaxA = max(x, max(y, z));
      currMinA = min(x, min(y, z));
      currMaxG = max(gx, max(gy, gz));
      currMinG = min(gx, min(gy, gz));
      maxY = currMaxA > maxY ? currMaxA + (currMaxA - currMinA) / 20 : maxY;
      minY = currMinA < minY ? currMinA - (currMaxA - currMinA) / 20 : minY;
      gmaxY = currMaxG > gmaxY ? currMaxG + (currMaxG - currMinG) / 20 : gmaxY;
      gminY = currMinG < gminY ? currMinG - (currMaxG - currMinG) / 20 : gminY;
    }
    maxY += 5;
    minY -= 5;
    gmaxY += 5;
    gminY -= 5;

    // If graph data is empty, show a message instead of SensorChart
    bool hasAccData = accX.isNotEmpty && accY.isNotEmpty && accZ.isNotEmpty;
    bool hasGyroData = gyroX.isNotEmpty && gyroY.isNotEmpty && gyroZ.isNotEmpty;

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
                      // Color.fromARGB(255, 132, 169, 155),
                      Colors.white10,
                      Color.fromRGBO(224, 224, 224, 1),
                    ],
                    stops: [0.09, 0.55],
                  ),
                ),
              ),
              Scaffold(
                backgroundColor: Colors.transparent,
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
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
                          selectedColor: Colors.white,
                          fillColor: Color.fromARGB(255, 132, 169, 155),
                          // fillColor: Colors.white70,
                          color: Color.fromARGB(255, 65, 64, 64),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Text("${dataPointsLength}"),
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
                          hasAccData
                              ? SensorChart(
                                  xData: accX,
                                  yData: accY,
                                  zData: accZ,
                                  minY: minY,
                                  maxY: maxY,
                                  showX: true,
                                  showY: true,
                                  showZ: true,
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Text(
                                    'No accelerometer data to plot.',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                )
                        else
                          hasGyroData
                              ? SensorChart(
                                  xData: gyroX,
                                  yData: gyroY,
                                  zData: gyroZ,
                                  minY: gminY,
                                  maxY: gmaxY,
                                  showX: true,
                                  showY: true,
                                  showZ: true,
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Text(
                                    'No gyroscope data to plot.',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                        SizedBox(height: 20),
                        Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Activity Analysis',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    DropdownMenuWidget(
                                      selectedValue: selectedAnalysis,
                                      onChanged: _onDropdownChanged,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                SizedBox(
                                  height: 200,
                                  child:
                                      // if (selectedAnalysis == 'Today')
                                      // FutureBuilder<Map<String, Duration>>(
                                      //   future: todayDurationsFuture,
                                      //   builder: (context, snapshot) {
                                      //     if (snapshot.connectionState ==
                                      //         ConnectionState.waiting) {
                                      //       return const Center(
                                      //         child: CircularProgressIndicator(),
                                      //       );
                                      //     } else if (snapshot.hasError) {
                                      //       return Text(
                                      //           'Error loading activity data: ${snapshot.error}');
                                      //     } else if (!snapshot.hasData ||
                                      //         snapshot.data!.isEmpty) {
                                      //       return const Text(
                                      //           'No activity data available for today.');
                                      //     }

                                      //     final activityDurations =
                                      //         snapshot.data!; // Map<String, Duration>

                                      //     return _buildActivityTimeAnalysisChart(
                                      //         activityDurations);
                                      //   },
                                      // )
                                      selectedAnalysis == 'Today'
                                          ? ActivityChartWidget(
                                              notifier:
                                                  activityDurationsNotifier,
                                              // selectedAnalysis: selectedAnalysis,
                                              // onDropdownChanged: _onDropdownChanged,
                                              chartBuilder:
                                                  _buildActivityTimeAnalysisChart,
                                            )
                                          : (selectedAnalysis == 'Last Week'
                                              ? groupActivityChart(
                                                  summary: weeklySummary,
                                                  summaryType: 'weekly')
                                              : groupActivityChart(
                                                  summary: last4WeeksSummary,
                                                  summaryType: 'monthly')),

                                  // else
                                  //   _buildActivityTimeAnalysisChart(
                                  //       _calculateActivityDurations()),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        colorPalette(),
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
    final todayData = _liveWindow.where((entry) {
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

  double getCleanMaxY(double maxVal) {
    if (maxVal <= 30) return ((maxVal / 5).ceil() * 5).toDouble();
    if (maxVal <= 60) return ((maxVal / 10).ceil() * 10).toDouble();
    return ((maxVal / 60).ceil() * 60).toDouble();
  }

  Widget _buildActivityTimeAnalysisChart(
      Map<String, Duration> activityDurations) {
    final axisInfo = computeAxisTicks(activityDurations.values);
    // const allActivities = [
    //   "walking",
    //   "walking_upstairs",
    //   "walking_downstairs",
    //   "sitting",
    //   "standing",
    //   "laying"
    // ];
    final double intervalValue = axisInfo.unit == "s"
        ? axisInfo.interval.toDouble()
        : axisInfo.unit == "m"
            ? (axisInfo.interval * 60).toDouble()
            : (axisInfo.interval * 3600).toDouble();

    // return
    // Card(
    //   elevation: 10,
    //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    //   child: Padding(
    //     padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Row(
    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //           children: [
    //             const Text(
    //               'Activity Analysis',
    //               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    //             ),
    //             DropdownMenuWidget(
    //               selectedValue: selectedAnalysis,
    //               onChanged: _onDropdownChanged,
    //             ),
    //           ],
    //         ),
    //         const SizedBox(
    //           height: 8,
    //         ),
    //         SizedBox(
    //             height: 200,
    //             child:
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        minY: 0,
        maxY: axisInfo.unit == "s"
            ? axisInfo.maxValue.toDouble()
            : axisInfo.unit == "m"
                ? (axisInfo.maxValue * 60).toDouble()
                : (axisInfo.maxValue * 3600).toDouble(),
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
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    activity.split('_').map((s) => s[0].toUpperCase()).join(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 20,
            ),
          ),
          rightTitles: AxisTitles(
              sideTitles: SideTitles(
            showTitles: false,
          )),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              "Duration (${axisInfo.unit})",
              style: TextStyle(fontSize: 12),
            ),
            axisNameSize: 20,
            drawBelowEverything: true,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: intervalValue,
              getTitlesWidget: (value, meta) {
                int val = value.round();
                String label;
                if (axisInfo.unit == "h") {
                  label = "${(val / 3600).round()}";
                } else if (axisInfo.unit == "m") {
                  label = "${(val / 60).round()}";
                } else {
                  label = "${val}";
                }
                return Text(label, style: TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            horizontalInterval: intervalValue,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                )),
        borderData: FlBorderData(show: false),
        barGroups: allActivities.map((activity) {
          final seconds =
              activityDurations[activity]?.inSeconds.toDouble() ?? 0;
          final isCurrent =
              activity == 'running'; // or any logic to highlight one bar
          return BarChartGroupData(
            x: allActivities.indexOf(activity),
            barRods: [
              BarChartRodData(
                toY: seconds,
                width: 25,
                borderRadius: BorderRadius.circular(6),
                color: isCurrent ? Colors.orange : Colors.grey.shade300,
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: axisInfo.maxValue.toDouble(),
                  // toY: maxSeconds * 1.2,
                  color: Colors.transparent,
                ),
              ),
            ],
          );
        }).toList(),
      ),
      duration: const Duration(milliseconds: 250),
    );
    //             ),
    //       ],
    //     ),
    //   ),
    // );
  }
}
