import 'dart:async';

import 'package:fitwatch/utilities/databaseHelper.dart';

class SensorDataRepository {
  static final SensorDataRepository _instance =
      SensorDataRepository._internal(DatabaseHelper.instance);
  factory SensorDataRepository() => _instance;
  SensorDataRepository._internal(this.dbHelper);

  final DatabaseHelper dbHelper;
  final StreamController<List<Map<String, dynamic>>> _dataController =
      StreamController.broadcast();

  // SensorDataRepository(this.dbHelper);

  Stream<List<Map<String, dynamic>>> getRealtimeDataStream(
      {int limit = 10000}) {
    // Initial data load
    // This will fetch the latest data and emit it to the stream
    print("Fetching initial data for stream...");
    getRawData(limit: limit).then(_dataController.add);

    // Return the stream for UI
    return _dataController.stream;
  }

  // Insert raw sensor data
  Future<int> insertRawData(Map<String, dynamic> data) async {
    print("Insterting data to DB...");
    final db = await dbHelper.database;
    final id = await db.insert('raw_logs', data);

    // Notify listeners of new data
    // getRawData(limit: 100).then(_dataController.add);

    getRawData(limit: 500).then((data) {
      print("Emitting data stream of size: ${data.length}");
      _dataController.add(data);
    });
    return id;
  }

  Future<void> printAllTableContents() async {
    final db = await dbHelper.database;

    // Get all table names (excluding system tables)
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
    );

    for (final table in tables) {
      final tableName = table['name'];
      final data = await db.query(tableName.toString());

      print('\n===== TABLE: $tableName =====');
      for (var row in data) {
        print(row);
      }
    }
  }

  // Get raw data for analysis
  Future<List<Map<String, dynamic>>> getRawData({
    int? beforeId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 1000,
  }) async {
    final db = await dbHelper.database;

    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (beforeId != null) {
      where += ' AND id < ?';
      whereArgs.add(beforeId);
    }

    if (startDate != null) {
      where += ' AND timestamp >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      where += ' AND timestamp <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    return await db.query(
      'raw_logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  // Update daily summary
  Future<void> updateDailySummary(
      String date, String activity, int duration) async {
    final db = await dbHelper.database;

    await db.rawInsert('''
      INSERT OR REPLACE INTO daily_summary (date, activity, duration)
      VALUES (?, ?, COALESCE((SELECT duration FROM daily_summary WHERE date = ? AND activity = ?), 0) + ?)
    ''', [date, activity, date, activity, duration]);
  }

  // Get weekly data (from daily summaries)
  Future<List<Map<String, dynamic>>> getWeeklyData() async {
    final db = await dbHelper.database;

    // Get last 7 days of daily summaries
    final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));

    return await db.query(
      'daily_summary',
      where: 'date >= ?',
      whereArgs: [sevenDaysAgo.toIso8601String()],
    );
  }

  // Update weekly summary
  Future<void> updateWeeklySummary(
      String weekId, String activity, int duration) async {
    final db = await dbHelper.database;

    await db.rawInsert('''
      INSERT OR REPLACE INTO weekly_summary (week_id, activity, duration)
      VALUES (?, ?, COALESCE((SELECT duration FROM weekly_summary WHERE week_id = ? AND activity = ?), 0) + ?)
    ''', [weekId, activity, weekId, activity, duration]);
  }

  // Cleanup old data (keep only last 7 days of daily summaries and last 4 weeks of weekly summaries)
  Future<void> cleanupOldData() async {
    final db = await dbHelper.database;

    // Delete daily summaries older than 7 days
    final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
    await db.delete(
      'daily_summary',
      where: 'date < ?',
      whereArgs: [sevenDaysAgo.toIso8601String()],
    );

    // Delete weekly summaries older than 4 weeks
    final fourWeeksAgo = DateTime.now().subtract(Duration(days: 28));
    await db.delete(
      'weekly_summary',
      where: 'week_id < ?',
      whereArgs: [getWeekId(fourWeeksAgo)],
    );
  }

  // Helper to get week ID (e.g., "2024-W27")
  String getWeekId(DateTime date) {
    final year = date.year;
    final weekNumber =
        ((date.difference(DateTime(year, 1, 1)).inDays) / 7).floor() + 1;
    return '$year-W${weekNumber.toString().padLeft(2, '0')}';
  }

  Future<Map<String, Duration>> getTodayActivityDuration() async {
    final db = await dbHelper.database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Query all logs for today ordered by timestamp
    final todayData = await db.query(
      'raw_logs',
      where: 'timestamp >= ?',
      whereArgs: [todayStart.toIso8601String()],
      orderBy: 'timestamp ASC',
    );

    // Prepare durations map
    final durations = <String, Duration>{
      "walking": Duration.zero,
      "walking_upstairs": Duration.zero,
      "walking_downstairs": Duration.zero,
      "sitting": Duration.zero,
      "standing": Duration.zero,
      "laying": Duration.zero,
    };

    // Parameters
    const gapThreshold = Duration(seconds: 2); // treat >2s as a break

    String? currentActivity;
    DateTime? segmentStartTime;
    DateTime? lastTimestamp;

    for (final entry in todayData) {
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
    //print all the durations
    durations.forEach((activity, duration) {
      print('$activity: ${duration.inSeconds} seconds');
    });
    return durations;
  }
}
