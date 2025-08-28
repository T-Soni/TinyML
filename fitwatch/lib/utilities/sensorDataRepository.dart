import 'dart:async';
import 'package:intl/intl.dart';
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
    // print("Insterting data to DB...");
    final db = await dbHelper.database;
    final id = await db.insert('raw_logs', data);

    // Notify listeners of new data
    // getRawData(limit: 100).then(_dataController.add);

    getRawData(limit: 500).then((data) {
      // print("Emitting data stream of size: ${data.length}");
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

  // Get rolling 7-day activity summary
  /// Returns a map where keys are weekdays (e.g., 'Mon', 'Tue')
  Future<Map<String, Map<String, int>>> getRolling7DaysActivitySummary() async {
    final db = await dbHelper.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Collect last 7 days dates (including today)
    final List<DateTime> last7Days = List.generate(
      7,
      (i) => today.subtract(Duration(days: 6 - i)),
    );

    // Format dates as 'yyyy-MM-dd' for database querying
    final List<String> dateStrings =
        last7Days.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList();

    // Query daily summaries for last 7 days
    final result = await db.query(
      'daily_summary',
      where: 'date IN (${List.filled(dateStrings.length, '?').join(',')})',
      whereArgs: dateStrings,
    );

    // Prepare activities list
    final activities = [
      'WALKING',
      'WALKING_UPSTAIRS',
      'WALKING_DOWNSTAIRS',
      'SITTING',
      'STANDING',
      'LAYING',
    ];

    // Output structure: {weekday: {activity: duration, ...}, ...}
    final Map<String, Map<String, int>> summary = {};

    for (int i = 0; i < last7Days.length; i++) {
      final date = dateStrings[i];
      final weekday =
          DateFormat('EEE').format(last7Days[i]); // 'Mon', 'Tue', etc.

      // Initialize durations as 0 for all activities
      summary[weekday] = {for (var a in activities) a: 0};

      // Filter results for this date
      final dayEntries = result.where((row) => row['date'] == date);

      for (final row in dayEntries) {
        final activity = row['activity']?.toString();
        final duration = row['duration'] is int
            ? row['duration'] as int
            : int.tryParse(row['duration'].toString()) ?? 0;
        if (activity != null && summary[weekday]!.containsKey(activity)) {
          summary[weekday]![activity] = duration;
        }
      }
    }

    return summary;
  }



  Future<Map<String, Map<String, int>>> getLast4WeeksActivitySummary() async {
    final db = await dbHelper.database;
    // Query all weekly summaries ordered by week_id
    final List<Map<String, dynamic>> result = await db.query(
      'weekly_summary',
      orderBy:
          'week_id ASC', // Order from oldest to newest for chronological display
    );

    final Map<String, Map<String, int>> summary = {};

    const allActivities = [
      'walking',
      'walking_upstairs',
      'walking_downstairs',
      'sitting',
      'standing',
      'laying',
    ];

    for (final row in result) {
      final weekId = row['week_id'] as String;
      final activity = row['activity']?.toString().toLowerCase() ?? 'unknown';
      final duration = row['duration'] as int;

      // If this is the first time we've seen this week, add it to the map
      // and initialize all possible activities with a duration of 0.
      summary.putIfAbsent(
          weekId, () => {for (var act in allActivities) act: 0});

      // Update the duration for the specific activity from the database row.
      if (summary[weekId]!.containsKey(activity)) {
        summary[weekId]![activity] = duration;
      }
    }

    return summary;
  }
}
