class AxisTickInfo {
  final String unit; // "s", "m", "h"
  final int maxValue; // in unit (not seconds)
  final int interval; // in unit (not seconds)
  final List<int> tickValues; // in unit (not seconds)

  AxisTickInfo(this.unit, this.maxValue, this.interval, this.tickValues);
}

AxisTickInfo computeAxisTicks(Iterable<Duration> durations) {
  if (durations.isEmpty || durations.every((d) => d.inSeconds == 0)) {
    return AxisTickInfo("s", 10, 2, [0, 2, 4, 6, 8, 10]);
  }

  final maxSeconds =
      durations.map((d) => d.inSeconds).reduce((a, b) => a > b ? a : b);

  String unit;
  int maxUnitValue; // max in chosen unit
  int interval;

  if (maxSeconds < 120) {
    // Use seconds
    unit = "s";
    maxUnitValue = ((maxSeconds + 9) ~/ 10) * 10; // round up to next 10 seconds
  } else if (maxSeconds < 7200) {
    // Use minutes
    unit = "m";
    maxUnitValue = ((maxSeconds / 60).ceil());
    // round up to next 5 or 10 minutes for nice intervals
    if (maxUnitValue <= 10) {
      maxUnitValue = ((maxUnitValue + 4) ~/ 5) * 5;
    } else if (maxUnitValue <= 30) {
      maxUnitValue = ((maxUnitValue + 9) ~/ 10) * 10;
    } else {
      maxUnitValue = ((maxUnitValue + 14) ~/ 15) * 15;
    }
  } else {
    // Use hours
    unit = "h";
    maxUnitValue = ((maxSeconds / 3600).ceil());
    if (maxUnitValue <= 5) {
      maxUnitValue = 5;
    } else if (maxUnitValue <= 10) {
      maxUnitValue = 10;
    } else if (maxUnitValue <= 20) {
      maxUnitValue = 20;
    } else {
      // round up to next multiple of 10
      maxUnitValue = ((maxUnitValue + 9) ~/ 10) * 10;
    }
  }

  // Find interval so that ticks are at whole units and tick count is <= 5
  int tickCount = 0;
  for (int i = 1; i <= maxUnitValue; i++) {
    if (maxUnitValue % i == 0 && (maxUnitValue ~/ i) <= 4) {
      // 5 ticks max
      interval = i;
      break;
    }
  }
  // If not found, pick interval so that tick count is <= 5
  interval = (maxUnitValue / 4).ceil();

  List<int> tickValues = List.generate(5, (i) => i * interval)
      .where((v) => v <= maxUnitValue)
      .toList();
  if (tickValues.last != maxUnitValue) tickValues.add(maxUnitValue);
// if (interval == null || interval == 0) interval = 1;
  return AxisTickInfo(unit, maxUnitValue, interval, tickValues);
}
