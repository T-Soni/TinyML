import 'package:flutter/material.dart';

Color getActivityColor(String activity) {
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

const allActivities = [
  "walking",
  "walking_upstairs",
  "walking_downstairs",
  "sitting",
  "standing",
  "laying"
];
