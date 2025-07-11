import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fitwatch/utilities/ActivityColors.dart';

final List<String> weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
Widget groupActivityChart() {
  return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      minY: 0,
      maxY: 10, // Adjust to fit the range of activities
      titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      "${weekDays[value.toInt()]}",
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                },
                reservedSize: 20),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
          leftTitles: AxisTitles(
              axisNameWidget: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Duration"),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: Icon(
                      Icons.arrow_right_alt,
                      size: 20,
                      weight: 1,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              // axisNameWidget: Text("Duration (${axisInfo.unit})"),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                // interval: intervalValue,
                // getTitlesWidget: (value, meta) {
                //   int val = value.round();
                //   String label;
                //   if (axisInfo.unit == 'h') {
                //     label = "${(val / 3600).round()}";
                //   } else if (axisInfo.unit == 'm') {
                //     label = "${(val / 60).round()}";
                //   } else {
                //     label = "$val";
                //   }
                //   return Text(
                //     label,
                //     style: TextStyle(fontSize: 10),
                //   );
                // }
              ))),
      gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          // horizontalInterval: intervalValue,,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 0.5,
              )),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          left: BorderSide(color: Colors.black, width: 1),
          bottom: BorderSide(color: Colors.black, width: 1),
          top: BorderSide.none,
          right: BorderSide.none,
        ),
      ),
      barGroups: [
        BarChartGroupData(
            x: 0,
            barRods: allActivities.map((activity) {
              final color = getActivityColor(activity);
              return BarChartRodData(
                toY: (6 - allActivities.indexOf(activity)) + 2.0,
                width: 2,
                color: color,
                borderRadius: BorderRadius.circular(4),
              );
            }).toList()),
        BarChartGroupData(
            x: 1,
            barRods: allActivities.map((activity) {
              final color = getActivityColor(activity);
              return BarChartRodData(
                toY: (6 - allActivities.indexOf(activity)) + 2.0,
                width: 2,
                color: color,
                borderRadius: BorderRadius.circular(4),
              );
            }).toList()),
        BarChartGroupData(
            x: 2,
            barRods: allActivities.map((activity) {
              final color = getActivityColor(activity);
              return BarChartRodData(
                toY: (6 - allActivities.indexOf(activity)) + 2.0,
                width: 2,
                color: color,
                borderRadius: BorderRadius.circular(4),
              );
            }).toList()),
        BarChartGroupData(
            x: 3,
            barRods: allActivities.map((activity) {
              final color = getActivityColor(activity);
              return BarChartRodData(
                toY: (6 - allActivities.indexOf(activity)) + 2.0,
                width: 2,
                color: color,
                borderRadius: BorderRadius.circular(4),
              );
            }).toList()),
        BarChartGroupData(
            x: 4,
            barRods: allActivities.map((activity) {
              final color = getActivityColor(activity);
              return BarChartRodData(
                toY: (6 - allActivities.indexOf(activity)) + 2.0,
                width: 2,
                color: color,
                borderRadius: BorderRadius.circular(4),
              );
            }).toList()),
        BarChartGroupData(
            x: 5,
            barRods: allActivities.map((activity) {
              final color = getActivityColor(activity);
              return BarChartRodData(
                toY: (6 - allActivities.indexOf(activity)) + 2.0,
                width: 2,
                color: color,
                borderRadius: BorderRadius.circular(4),
              );
            }).toList()),
        BarChartGroupData(
            x: 6,
            barRods: allActivities.map((activity) {
              final color = getActivityColor(activity);
              return BarChartRodData(
                toY: (6 - allActivities.indexOf(activity)) + 2.0,
                width: 2,
                color: color,
                borderRadius: BorderRadius.circular(4),
              );
            }).toList()),
      ]));
}
