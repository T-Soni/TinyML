import 'dart:async';

import 'package:fitwatch/utilities/databaseHelper.dart';
import 'package:fitwatch/utilities/sensorDataRepository.dart';
import 'package:flutter/material.dart';
import 'package:fitwatch/session_data.dart';

class DataLogs extends StatefulWidget {
  final String status;
  final SensorDataRepository sensorRepo;
  const DataLogs({super.key, required this.status, required this.sensorRepo});

  @override
  State<DataLogs> createState() => _DataLogsState();
}

class _DataLogsState extends State<DataLogs> {
  final int pageSize = 100;
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> historyData = [];
  Set<int> liveIds = {};

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  int _lastId = -1;

  late StreamSubscription<List<Map<String, dynamic>>> _dataSubscription;

  // Replace local liveData and liveIds with:
  final session = SessionData();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
    _setupDataStream();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dataSubscription.cancel();
    super.dispose();
  }

  void _setupDataStream() {
    _dataSubscription =
        widget.sensorRepo.getRealtimeDataStream().listen((data) {
      if (!mounted || data.isEmpty) return;
      int? latestHistoryId =
          historyData.isNotEmpty ? historyData.first['id'] as int : null;
      // Only add to liveData if there is new data newer than historyData
      if (latestHistoryId != null) {
        final newLive =
            data.where((entry) => entry['id'] > latestHistoryId).toList();
        setState(() {
          session.liveData = newLive;
          session.liveIds = session.liveData.map((e) => e['id'] as int).toSet();
        });
      } else {
        // If no history yet, don't show any liveData until new data arrives
        setState(() {
          session.liveData = [];
          session.liveIds = {};
        });
      }
    });
  }

  Future<void> _loadData() async {
    final latestLiveId =
        session.liveData.isNotEmpty ? session.liveData.last['id'] : null;
    final logs = await widget.sensorRepo.getRawData(
      limit: pageSize,
      beforeId: latestLiveId,
    );
    // Filter out duplicates
    final filteredLogs =
        logs.where((row) => !liveIds.contains(row['id'])).toList();

    setState(() {
      historyData = filteredLogs;
      _lastId = filteredLogs.isNotEmpty ? filteredLogs.last['id'] : -1;
      _isLoading = false;
      _hasMoreData = logs.length == pageSize;
    });
  }

  Future<void> _fetchMoreData() async {
    if (_isFetchingMore || !_hasMoreData || _lastId == -1) return;

    setState(() => _isFetchingMore = true);

    final logs = await widget.sensorRepo.getRawData(
      limit: pageSize,
      beforeId: _lastId,
    );
    // Filter out duplicates
    final filteredLogs =
        logs.where((row) => !liveIds.contains(row['id'])).toList();

    if (mounted) {
      setState(() {
        historyData.addAll(filteredLogs);
        _lastId = filteredLogs.isNotEmpty ? filteredLogs.last['id'] : _lastId;
        _hasMoreData = logs.length == pageSize;
        _isFetchingMore = false;
      });
    }
  }

  Widget _buildDataRow(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              data['timestamp'].toString().split('T').last.split('.').first,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          _buildSensorChip(
              'A',
              '${(data['acc_x'] ?? 0.0).toStringAsFixed(1)}'
                  '/${(data['acc_y'] ?? 0.0).toStringAsFixed(1)}'
                  '/${(data['acc_z'] ?? 0.0).toStringAsFixed(1)}'),
          _buildSensorChip(
              'G',
              '${(data['gyro_x'] ?? 0.0).toStringAsFixed(1)}'
                  '/${(data['gyro_y'] ?? 0.0).toStringAsFixed(1)}'
                  '/${(data['gyro_z'] ?? 0.0).toStringAsFixed(1)}'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getActivityColor(data['activity']),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              data['activity'].toString().substring(0, 3).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorChip(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10)),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _getActivityColor(String activity) {
    switch (activity.toLowerCase()) {
      case 'walking':
        return Colors.blue;
      case 'walking_upstairs':
        return Colors.green;
      case 'walking_downstairs':
        return Colors.red;
      case 'sitting':
        return Colors.amber;
      case 'standing':
        return Colors.orange;
      case 'laying':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only combine liveData and historyData if liveData is not empty
    final combinedData = session.liveData.isNotEmpty
        ? [...session.liveData, ...historyData]
        : historyData;

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Sensor Data',
          style: TextStyle(
              fontSize: 25, fontWeight: FontWeight.w600, color: Colors.black54),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              widget.status == "BLEconnected"
                  ? Icons.bluetooth_connected
                  : widget.status == "Connected"
                      ? Icons.wifi
                      : Icons.wifi_off,
              color: widget.status == "BLEconnected"
                  ? Colors.blue
                  : widget.status == "Connected"
                      ? Colors.green
                      : Colors.red,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text("CURRENT READING",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      session.liveData.isNotEmpty
                          ? _buildDataRow(session.liveData.first)
                          : _buildDataRow({
                              'timestamp': '--:--:--',
                              'acc_x': 0.0,
                              'acc_y': 0.0,
                              'acc_z': 0.0,
                              'gyro_x': 0.0,
                              'gyro_y': 0.0,
                              'gyro_z': 0.0,
                              'activity': 'waiting'
                            }),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("HISTORY",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: combinedData.length + (_hasMoreData ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= combinedData.length) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return _buildDataRow(combinedData[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore) {
      _fetchMoreData();
    }
  }
}
