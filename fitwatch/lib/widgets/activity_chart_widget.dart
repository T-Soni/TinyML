import 'package:flutter/material.dart';

class ActivityChartWidget extends StatelessWidget {
  final ValueNotifier<Map<String, Duration>> notifier;
  // final String selectedAnalysis;
  // final void Function(String) onDropdownChanged;
  final Widget Function(Map<String, Duration>) chartBuilder;

  const ActivityChartWidget({
    Key? key,
    required this.notifier,
    // required this.selectedAnalysis,
    // required this.onDropdownChanged,
    required this.chartBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, Duration>>(
      valueListenable: notifier,
      builder: (context, durations, _) {
        if (durations.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }
        return chartBuilder(durations);
      },
    );
  }
}
