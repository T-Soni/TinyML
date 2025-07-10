// import 'package:fitwatch/utilities/axis_tick_helper.dart';
// import 'package:flutter/material.dart';

// class MyWidget extends StatelessWidget {
//   MyWidget({super.key});

//   Map<String, Duration> activityDurations = {
//     "walking": Duration(minutes: 30),
//     "walking_upstairs": Duration(minutes: 10),
//     "walking_downstairs": Duration(minutes: 5),
//     "sitting": Duration(minutes: 60),
//     "standing": Duration(minutes: 20),
//     "laying": Duration(minutes: 15),
//   };
// //  Widget _buildActivityTimeAnalysisChart(
// //       Map<String, Duration> activityDurations) {
//   final axisInfo = computeAxisTicks(activityDurations.values);
//   final allActivities = [
//     "walking",
//     "walking_upstairs",
//     "walking_downstairs",
//     "sitting",
//     "standing",
//     "laying"
//   ];
//   final double intervalValue = axisInfo.unit == "s"
//       ? axisInfo.interval.toDouble()
//       : axisInfo.unit == "m"
//           ? (axisInfo.interval * 60).toDouble()
//           : (axisInfo.interval * 3600).toDouble();

//   // final maxSeconds = activityDurations.values.fold<double>(
//   //     0, (max, d) => d.inSeconds > max ? d.inSeconds.toDouble() : max);

//   // double maxSeconds = getCleanMaxY(
//   //   activityDurations.values.fold<double>(
//   //     0,
//   //     (max, d) => d.inSeconds > max ? d.inSeconds.toDouble() : max,
//   //   ),
//   // );
//   // double interval;
//   // if (maxSeconds <= 30) {
//   //   interval = 5;
//   // } else if (maxSeconds <= 60) {
//   //   interval = 10;
//   // } else {
//   //   interval = 60;
//   // }

// // Round up to the next 30s or 1min for a cleaner axis
//   // double maxSeconds = activityDurations.values.fold<double>(
//   //     0, (max, d) => d.inSeconds > max ? d.inSeconds.toDouble() : max);
//   // if (maxSeconds < 60) {
//   //   maxSeconds = ((maxSeconds / 10).ceil() * 10).toDouble();
//   // } else {
//   //   maxSeconds = ((maxSeconds / 60).ceil() * 60).toDouble();
//   // }
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 10,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Activity Analysis',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 DropdownMenuWidget(
//                   selectedValue: selectedAnalysis,
//                   onChanged: _onDropdownChanged,
//                 ),
//               ],
//             ),
//             const SizedBox(
//               height: 8,
//             ),
//             SizedBox(
//                 height: 200,
//                 child: BarChart(
//                   BarChartData(
//                     alignment: BarChartAlignment.spaceAround,
//                     minY: 0,
//                     maxY: axisInfo.unit == "s"
//                         ? axisInfo.maxValue.toDouble()
//                         : axisInfo.unit == "m"
//                             ? (axisInfo.maxValue * 60).toDouble()
//                             : (axisInfo.maxValue * 3600).toDouble(),
//                     // maxY: maxSeconds,
//                     // maxY: maxSeconds * 1.2,
//                     barTouchData: BarTouchData(
//                       enabled: true,
//                       touchTooltipData: BarTouchTooltipData(
//                         getTooltipItem: (group, groupIndex, rod, rodIndex) {
//                           final activity = allActivities[group.x];
//                           final duration = Duration(seconds: rod.toY.round());
//                           String timeText;
//                           if (duration.inHours > 0) {
//                             timeText =
//                                 '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
//                           } else if (duration.inMinutes > 0) {
//                             timeText =
//                                 '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
//                           } else {
//                             timeText = '${duration.inSeconds}s';
//                           }
//                           return BarTooltipItem(
//                             timeText,
//                             const TextStyle(
//                               color: Colors.white,
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                             ),
//                             children: [
//                               TextSpan(
//                                 text: '\n${activity.replaceAll('_', ' ')}',
//                                 style: TextStyle(
//                                   color: Colors.white70,
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.normal,
//                                 ),
//                               ),
//                             ],
//                           );
//                         },
//                         // tooltipBgColor: Colors.black87,
//                         tooltipMargin: 8,
//                         tooltipPadding: const EdgeInsets.symmetric(
//                             horizontal: 12, vertical: 8),
//                         tooltipBorder: BorderSide.none,
//                         direction: TooltipDirection.top,
//                       ),
//                     ),
//                     titlesData: FlTitlesData(
//                       show: true,
//                       bottomTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           getTitlesWidget: (value, meta) {
//                             final activity = allActivities[value.toInt()];
//                             return Padding(
//                               padding: const EdgeInsets.only(top: 6.0),
//                               child: Text(
//                                 activity
//                                     .split('_')
//                                     .map((s) => s[0].toUpperCase())
//                                     .join(),
//                                 textAlign: TextAlign.center,
//                                 style: const TextStyle(fontSize: 10),
//                               ),
//                             );
//                           },
//                           reservedSize: 20,
//                         ),
//                       ),
//                       rightTitles: AxisTitles(
//                           sideTitles: SideTitles(
//                         showTitles: false,
//                       )),
//                       topTitles:
//                           AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                       leftTitles: AxisTitles(
//                         axisNameWidget: Text(
//                           "Duration (${axisInfo.unit})",
//                           style: TextStyle(fontSize: 12),
//                         ),
//                         axisNameSize: 20,
//                         drawBelowEverything: true,
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           reservedSize: 25,
//                           // interval: maxSeconds > 60
//                           //     ? (maxSeconds / 5).roundToDouble()
//                           //     : maxSeconds > 10
//                           //         ? 10
//                           //         : 1,
//                           interval: intervalValue,
//                           // interval: interval,
//                           // getTitlesWidget: (value, meta) {
//                           //   final duration = Duration(seconds: value.toInt());
//                           //   if (duration.inHours > 0) {
//                           //     return Text('${duration.inHours}h',
//                           //         // '${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
//                           //         style: const TextStyle(fontSize: 10));
//                           //   } else if (duration.inMinutes > 0) {
//                           //     return Text(
//                           //         '${duration.inMinutes}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
//                           //         style: const TextStyle(fontSize: 10));
//                           //   } else {
//                           //     return Text('${duration.inSeconds}s',
//                           //         style: const TextStyle(fontSize: 10));
//                           //   }
//                           // },
//                           getTitlesWidget: (value, meta) {
//                             int val = value.round();
//                             String label;
//                             if (axisInfo.unit == "h") {
//                               label = "${(val / 3600).round()}";
//                             } else if (axisInfo.unit == "m") {
//                               label = "${(val / 60).round()}";
//                             } else {
//                               label = "${val}";
//                             }
//                             return Text(label, style: TextStyle(fontSize: 10));
//                           },
//                         ),
//                       ),
//                     ),
//                     gridData: FlGridData(
//                         // show: false
//                         show: true,
//                         drawHorizontalLine: true,
//                         horizontalInterval: intervalValue,
//                         drawVerticalLine: false,
//                         getDrawingHorizontalLine: (value) => FlLine(
//                               color: Colors.grey.shade300,
//                               strokeWidth: 1,
//                             )),
//                     borderData: FlBorderData(show: false),
//                     barGroups: allActivities.map((activity) {
//                       final seconds =
//                           activityDurations[activity]?.inSeconds.toDouble() ??
//                               0;
//                       final isCurrent = activity ==
//                           'running'; // or any logic to highlight one bar
//                       return BarChartGroupData(
//                         x: allActivities.indexOf(activity),
//                         barRods: [
//                           BarChartRodData(
//                             toY: seconds,
//                             width: 25,
//                             borderRadius: BorderRadius.circular(6),
//                             color: isCurrent
//                                 ? Colors.orange
//                                 : Colors.grey.shade300,
//                             backDrawRodData: BackgroundBarChartRodData(
//                               show: true,
//                               toY: axisInfo.maxValue.toDouble(),
//                               // toY: maxSeconds * 1.2,
//                               color: Colors.transparent,
//                             ),
//                           ),
//                         ],
//                       );
//                     }).toList(),
//                   ),
//                   duration: const Duration(milliseconds: 250),
//                 )),
//           ],
//         ),
//       ),
//     );
//     // }
//   }
// }
