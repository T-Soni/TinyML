import 'package:fitwatch/utilities/ActivityColors.dart';
import 'package:flutter/material.dart';

Widget colorPalette() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: SizedBox(
      width: double.infinity,
      height: 80,
      // child: Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: const Border(
            left: BorderSide(width: 1, color: Colors.white),
            bottom: BorderSide(width: 2, color: Colors.white),
          ),
          color: Colors.white70,
          borderRadius: BorderRadius.circular(12),
        ),
        // color: Colors.white70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ColorLabel(
                    allActivities[0], getActivityColor(allActivities[0])),
                ColorLabel(
                    allActivities[1], getActivityColor(allActivities[1])),
                ColorLabel(
                    allActivities[2], getActivityColor(allActivities[2])),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ColorLabel(
                    allActivities[3], getActivityColor(allActivities[3])),
                ColorLabel(
                    allActivities[4], getActivityColor(allActivities[4])),
                ColorLabel(
                    allActivities[5], getActivityColor(allActivities[5])),
              ],
            ),
          ],
        ),
      ),
      // ),
    ),
  );
}

Widget ColorLabel(String activity, Color color) {
  return Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          border: BoxBorder.all(width: 1, color: Colors.black),
          color: color,
        ),
      ),
      SizedBox(width: 8),
      Text(activity),
    ],
  );
}
