import 'package:fitwatch/sensorChart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalysisScreen extends StatefulWidget {
  final List<Map<String, dynamic>> dataHistory;
  final String status;

  const AnalysisScreen({
    required this.dataHistory,
    required this.status,
    super.key,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int selectedIndex = 0; // 0 = Accelerometer, 1 = Gyrometer
  final int _displayPoints = 50;
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
    // double maxY = 10, minY = -10; // Default ranges
    // double gmaxY = 10, gminY = -10;

    int dataPointsLength =
        (50 < widget.dataHistory.length) ? 50 : widget.dataHistory.length;
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
      final data = widget.dataHistory[i];
      final x = _parseDouble(data['acc_x']);
      final y = _parseDouble(data['acc_y']);
      final z = _parseDouble(data['acc_z']);
      final gx = _parseDouble(data['gyro_x']);
      final gy = _parseDouble(data['gyro_y']);
      final gz = _parseDouble(data['gyro_z']);

      accX.add(FlSpot(50 - i.toDouble(), x));
      accY.add(FlSpot(50 - i.toDouble(), y));
      accZ.add(FlSpot(50 - i.toDouble(), z));

      gyroX.add(FlSpot(50 - i.toDouble(), gx));
      gyroY.add(FlSpot(50 - i.toDouble(), gy));
      gyroZ.add(FlSpot(50 - i.toDouble(), gz));

      maxY = x > maxY ? x : maxY;
      minY = x < minY ? x : minY;
      gmaxY = gx > gmaxY ? gx : gmaxY;
      gminY = gx < gminY ? gx : gminY;
    }

    maxY += 5;
    minY -= 5;
    gmaxY += 5;
    gminY -= 5;

    return Scaffold(
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
                borderRadius: BorderRadius.circular(12),
                selectedColor: Colors.white,
                fillColor: Colors.blue,
                color: Colors.black,
                constraints: const BoxConstraints(minWidth: 150, minHeight: 40),
                children: const [
                  Text("Accelerometer"),
                  Text("Gyrometer"),
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
                  maxY: maxY,
                  showX: true,
                  showY: true,
                  showZ: true,
                ),

              // ),
              SizedBox(
                height: 10,
              ),
              Text('Bar Chart'),
            ],
          ),
        ),
      ),
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
}
