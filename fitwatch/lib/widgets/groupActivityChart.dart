// import 'package:fitwatch/utilities/axis_tick_helper.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:fitwatch/utilities/ActivityColors.dart';

// final List<String> weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
// Widget groupActivityChart(
//     {required Future<Map<String, Map<String, int>>> summary,
//     required String summaryType}) {
//   return FutureBuilder(
//       future: summary,
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return Center(child: CircularProgressIndicator());
//         }
//         final summary = snapshot.data!;

//         // Print the map for debug

//         // print("===== Weekly Summary =====");
//         // summary.forEach((weekday, activityMap) {
//         //   print("$weekday:");
//         //   activityMap.forEach((activity, duration) {
//         //     print("  $activity: $duration");
//         //   });
//         // });
//         // print("=========================");

//         final List<String> days = summary.keys.toList();
//         // days.forEach((day) => print(day));

//         // Get all durations for the axis ticks
//         final allDurations = summary.values
//             .expand((activityMap) => activityMap.values)
//             .map((seconds) => Duration(seconds: seconds));

//         final axisInfo = computeAxisTicks(allDurations);

//         final double intervalValue = axisInfo.unit == "s"
//             ? axisInfo.interval.toDouble()
//             : axisInfo.unit == "m"
//                 ? (axisInfo.interval * 60).toDouble()
//                 : (axisInfo.interval * 3600).toDouble();

//         // // Build the bar groups: one group per day from the map
//         final List<BarChartGroupData> groups =
//             List.generate(days.length, (index) {
//           final dayLabel = days[index];
//           final activityDurations = summary[dayLabel] ??
//               {for (var a in allActivities) a.toUpperCase(): 0};
//           return BarChartGroupData(
//             x: index,
//             barRods: allActivities.map((activity) {
//               // final color = Colors.pink;
//               final color = getActivityColor(activity);
//               final duration = activityDurations[activity.toUpperCase()] ?? 0;
//               return BarChartRodData(
//                 toY: duration.toDouble(),
//                 width: 2,
//                 color: color,
//                 borderRadius: BorderRadius.circular(4),
//               );
//             }).toList(),
//           );
//         });

//         return BarChart(BarChartData(
//           alignment: BarChartAlignment.spaceAround,
//           minY: 0,
//           maxY: axisInfo.unit == "s"
//               ? axisInfo.maxValue.toDouble()
//               : axisInfo.unit == "m"
//                   ? (axisInfo.maxValue * 60).toDouble()
//                   : (axisInfo.maxValue * 3600).toDouble(),
//           // barTouchData: BarTouchData(
//           //   enabled: true,
//           //   touchTooltipData: BarTouchTooltipData(
//           //     getTooltipItem: (group, groupIndex, rod, rodIndex) {
//           //       final activity = allActivities[group.x];
//           //       final duration = Duration(seconds: rod.toY.round());
//           //       String timeText;
//           //       if (duration.inHours > 0) {
//           //         timeText =
//           //             '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
//           //       } else if (duration.inMinutes > 0) {
//           //         timeText =
//           //             '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
//           //       } else {
//           //         timeText = '${duration.inSeconds}s';
//           //       }
//           //       return BarTooltipItem(
//           //         timeText,
//           //         const TextStyle(
//           //           color: Colors.white,
//           //           fontSize: 14,
//           //           fontWeight: FontWeight.bold,
//           //         ),
//           //         children: [
//           //           TextSpan(
//           //             text: '\n${activity.replaceAll('_', ' ')}',
//           //             style: TextStyle(
//           //               color: Colors.white70,
//           //               fontSize: 10,
//           //               fontWeight: FontWeight.normal,
//           //             ),
//           //           ),
//           //         ],
//           //       );
//           //     },
//           //     // tooltipBgColor: Colors.black87,
//           //     tooltipMargin: 8,
//           //     tooltipPadding:
//           //         const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           //     tooltipBorder: BorderSide.none,
//           //     direction: TooltipDirection.top,
//           //   ),
//           // ),
//           titlesData: FlTitlesData(
//               show: true,
//               bottomTitles: AxisTitles(
//                 sideTitles: SideTitles(
//                     showTitles: true,
//                     getTitlesWidget: (value, meta) {
//                       return Padding(
//                         padding: const EdgeInsets.only(top: 6.0),
//                         child: Text(
//                           days[value.toInt()],
//                           style: TextStyle(fontSize: 12),
//                         ),
//                       );
//                     },
//                     reservedSize: 20),
//               ),
//               rightTitles: AxisTitles(
//                 sideTitles: SideTitles(
//                   showTitles: false,
//                 ),
//               ),
//               topTitles: AxisTitles(
//                 sideTitles: SideTitles(
//                   showTitles: false,
//                 ),
//               ),
//               leftTitles: AxisTitles(
//                   axisNameSize: 20,
//                   axisNameWidget: Padding(
//                     padding: const EdgeInsets.only(top: 0, left: 10, bottom: 5),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Text(
//                           "Duration (${axisInfo.unit})",
//                           style: TextStyle(fontSize: 12),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.only(bottom: 0),
//                           child: Icon(
//                             Icons.arrow_right_alt,
//                             size: 20,
//                             weight: 1,
//                             color: Colors.black87,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 20,
//                       interval: intervalValue,
//                       getTitlesWidget: (value, meta) {
//                         int val = value.round();
//                         String label;
//                         if (axisInfo.unit == 'h') {
//                           label = "${(val / 3600).round()}";
//                         } else if (axisInfo.unit == 'm') {
//                           label = "${(val / 60).round()}";
//                         } else {
//                           label = "$val";
//                         }
//                         return Text(
//                           label,
//                           style: TextStyle(fontSize: 10),
//                         );
//                       }))),
//           gridData: FlGridData(
//               show: true,
//               drawHorizontalLine: true,
//               horizontalInterval: intervalValue,
//               drawVerticalLine: false,
//               getDrawingHorizontalLine: (value) => FlLine(
//                     color: Colors.grey.shade300,
//                     strokeWidth: 0.5,
//                   )),
//           borderData: FlBorderData(
//             show: true,
//             border: const Border(
//               left: BorderSide(color: Colors.black, width: 1),
//               bottom: BorderSide(color: Colors.black, width: 1),
//               top: BorderSide.none,
//               right: BorderSide.none,
//             ),
//           ),
//           barGroups: groups,
//           // [
//           //   BarChartGroupData(
//           //       x: 0,
//           //       barRods: allActivities.map((activity) {
//           //         final color = getActivityColor(activity);
//           //         return BarChartRodData(
//           //           toY: (6 - allActivities.indexOf(activity)) + 2.0,
//           //           width: 2,
//           //           color: color,
//           //           borderRadius: BorderRadius.circular(4),
//           //         );
//           //       }).toList()),
//           //   BarChartGroupData(
//           //       x: 1,
//           //       barRods: allActivities.map((activity) {
//           //         final color = getActivityColor(activity);
//           //         return BarChartRodData(
//           //           toY: (6 - allActivities.indexOf(activity)) + 2.0,
//           //           width: 2,
//           //           color: color,
//           //           borderRadius: BorderRadius.circular(4),
//           //         );
//           //       }).toList()),
//           //   BarChartGroupData(
//           //       x: 2,
//           //       barRods: allActivities.map((activity) {
//           //         final color = getActivityColor(activity);
//           //         return BarChartRodData(
//           //           toY: (6 - allActivities.indexOf(activity)) + 2.0,
//           //           width: 2,
//           //           color: color,
//           //           borderRadius: BorderRadius.circular(4),
//           //         );
//           //       }).toList()),
//           //   BarChartGroupData(
//           //       x: 3,
//           //       barRods: allActivities.map((activity) {
//           //         final color = getActivityColor(activity);
//           //         return BarChartRodData(
//           //           toY: (6 - allActivities.indexOf(activity)) + 2.0,
//           //           width: 2,
//           //           color: color,
//           //           borderRadius: BorderRadius.circular(4),
//           //         );
//           //       }).toList()),
//           //   BarChartGroupData(
//           //       x: 4,
//           //       barRods: allActivities.map((activity) {
//           //         final color = getActivityColor(activity);
//           //         return BarChartRodData(
//           //           toY: (6 - allActivities.indexOf(activity)) + 2.0,
//           //           width: 2,
//           //           color: color,
//           //           borderRadius: BorderRadius.circular(4),
//           //         );
//           //       }).toList()),
//           //   BarChartGroupData(
//           //       x: 5,
//           //       barRods: allActivities.map((activity) {
//           //         final color = getActivityColor(activity);
//           //         return BarChartRodData(
//           //           toY: (6 - allActivities.indexOf(activity)) + 2.0,
//           //           width: 2,
//           //           color: color,
//           //           borderRadius: BorderRadius.circular(4),
//           //         );
//           //       }).toList()),
//           //   BarChartGroupData(
//           //       x: 6,
//           //       barRods: allActivities.map((activity) {
//           //         final color = getActivityColor(activity);
//           //         return BarChartRodData(
//           //           toY: (6 - allActivities.indexOf(activity)) + 2.0,
//           //           width: 2,
//           //           color: color,
//           //           borderRadius: BorderRadius.circular(4),
//           //         );
//           //       }).toList()),
//           // ]
//         ));
//       });
// }
import 'package:fitwatch/utilities/axis_tick_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fitwatch/utilities/ActivityColors.dart';

const List<String> allActivities = [
  'walking',
  'walking_upstairs',
  'walking_downstairs',
  'sitting',
  'standing',
  'laying',
];

// ✅ FIXED: This function now uses the same logic as your sensorDataRepository.
String _getWeekId(DateTime date) {
  final year = date.year;
  final weekNumber =
      ((date.difference(DateTime(year, 1, 1)).inDays) / 7).floor() + 1;
  return '$year-W${weekNumber.toString().padLeft(2, '0')}';
}

Widget groupActivityChart({
  required Future<Map<String, Map<String, int>>> summary,
  required String summaryType,
}) {
  return FutureBuilder<Map<String, Map<String, int>>>(
    future: summary,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      final summaryData = snapshot.data ?? {};

      final now = DateTime.now();
      final lastFourWeeks = List.generate(4, (index) {
        final date = now.subtract(Duration(days: index * 7));
        return _getWeekId(date);
      }).reversed.toList();

      final xAxisLabels =
          summaryType == 'weekly' ? summaryData.keys.toList() : lastFourWeeks;

      if (xAxisLabels.isEmpty) {
        return const Center(child: Text("No data available for this period."));
      }

      final allDurations = summaryData.values
          .expand((activityMap) => activityMap.values)
          .map((seconds) => Duration(seconds: seconds));

      final axisInfo = computeAxisTicks(
          allDurations.isNotEmpty ? allDurations : [Duration.zero]);

      final double yAxisInterval = axisInfo.unit == "s"
          ? axisInfo.interval.toDouble()
          : axisInfo.unit == "m"
              ? (axisInfo.interval * 60).toDouble()
              : (axisInfo.interval * 3600).toDouble();

      final double maxY = axisInfo.unit == "s"
          ? axisInfo.maxValue.toDouble()
          : axisInfo.unit == "m"
              ? (axisInfo.maxValue * 60).toDouble()
              : (axisInfo.maxValue * 3600).toDouble();

      final double barWidth = summaryType == 'weekly' ? 5.0 : 10.0;

      final List<BarChartGroupData> groups =
          List.generate(xAxisLabels.length, (index) {
        final label = xAxisLabels[index];

        final activityDurations =
            summaryData[label] ?? {for (var a in allActivities) a: 0};

        return BarChartGroupData(
          x: index,
          barRods: allActivities.map((activity) {
            final color = getActivityColor(activity);

            int duration;
            if (summaryType == 'weekly') {
              duration = activityDurations[activity.toUpperCase()] ?? 0;
            } else {
              duration = activityDurations[activity.toLowerCase()] ?? 0;
            }

            return BarChartRodData(
              toY: duration.toDouble(),
              width: barWidth,
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            );
          }).toList(),
        );
      });

      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          minY: 0,
          maxY: maxY > 0 ? maxY : 10,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= xAxisLabels.length)
                    return const Text('');
                  final label = xAxisLabels[value.toInt()];

                  String title;
                  if (summaryType == 'weekly') {
                    title = label;
                  } else if (summaryType == 'last4weeks' ||
                      summaryType == 'monthly') {
                    title = label.split('-').last;
                  } else {
                    title = label;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(title, style: const TextStyle(fontSize: 12)),
                  );
                },
                reservedSize: 20,
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              axisNameSize: 20,
              axisNameWidget: Text(
                "Duration (${axisInfo.unit})",
                style: const TextStyle(fontSize: 12),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: yAxisInterval > 0 ? yAxisInterval : 1,
                getTitlesWidget: (value, meta) {
                  int val = value.round();
                  String label;
                  if (axisInfo.unit == 'h') {
                    label = (val / 3600).round().toString();
                  } else if (axisInfo.unit == 'm') {
                    label = (val / 60).round().toString();
                  } else {
                    label = val.toString();
                  }
                  return Text(label, style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            horizontalInterval: yAxisInterval > 0 ? yAxisInterval : 1,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              left: BorderSide(color: Colors.black, width: 1),
              bottom: BorderSide(color: Colors.black, width: 1),
            ),
          ),
          barGroups: groups,
        ),
      );
    },
  );
}
