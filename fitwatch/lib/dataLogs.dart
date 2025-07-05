import 'dart:async';
import 'package:fitwatch/utilities/databaseHelper.dart';
import 'package:fitwatch/utilities/sensorDataRepository.dart';
import 'package:flutter/material.dart';
import 'package:fitwatch/session_data.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class DataLogs extends StatefulWidget {
  final String status;
  final SensorDataRepository sensorRepo;
  const DataLogs({super.key, required this.status, required this.sensorRepo});

  @override
  State<DataLogs> createState() => _DataLogsState();
}

class _DataLogsState extends State<DataLogs> {
  static const int pageSize = 100;
  final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(firstPageKey: 0);

  final session = SessionData();
  late StreamSubscription<List<Map<String, dynamic>>> _dataSubscription;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    _setupDataStream();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _dataSubscription.cancel();
    super.dispose();
  }

  void _setupDataStream() {
    _dataSubscription =
        widget.sensorRepo.getRealtimeDataStream().listen((data) {
      if (!mounted || data.isEmpty) return;
      int? latestHistoryId = _pagingController.itemList?.isNotEmpty == true
          ? _pagingController.itemList!.first['id'] as int
          : null;
      if (latestHistoryId != null) {
        final newLive =
            data.where((entry) => entry['id'] > latestHistoryId).toList();
        setState(() {
          session.liveData = newLive;
          session.liveIds = session.liveData.map((e) => e['id'] as int).toSet();
        });
      } else {
        setState(() {
          session.liveData = [];
          session.liveIds = {};
        });
      }
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final logs = await widget.sensorRepo.getRawData(
        limit: pageSize,
        beforeId: pageKey == 0 ? null : pageKey,
      );
      final filteredLogs =
          logs.where((row) => !session.liveIds.contains(row['id'])).toList();
      final isLastPage = filteredLogs.length < pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(filteredLogs);
      } else {
        final nextPageKey = filteredLogs.last['id'];
        _pagingController.appendPage(filteredLogs, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
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
    return Scaffold(
      // appBar: AppBar(
      //   surfaceTintColor: Colors.transparent,
      //   backgroundColor: Colors.transparent,
      //   title: const Text(
      //     'Sensor Data',
      //     style: TextStyle(
      //         fontSize: 25, fontWeight: FontWeight.w600, color: Colors.black54),
      //   ),
      //   actions: [
      //     Padding(
      //       padding: const EdgeInsets.all(12.0),
      //       child: Icon(
      //         widget.status == "BLEconnected"
      //             ? Icons.bluetooth_connected
      //             : widget.status == "Connected"
      //                 ? Icons.wifi
      //                 : Icons.wifi_off,
      //         color: widget.status == "BLEconnected"
      //             ? Colors.blue
      //             : widget.status == "Connected"
      //                 ? Colors.green
      //                 : Colors.red,
      //       ),
      //     ),
      //   ],
      // ),
      body: Column(
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
            child: Text("LIVE DATA",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (session.liveData.isNotEmpty)
            Flexible(
              flex: 2,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: session.liveData.length,
                itemBuilder: (context, index) =>
                    _buildDataRow(session.liveData[index]),
              ),
            ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child:
                Text("HISTORY", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Flexible(
            flex: 3,
            child: PagedListView<int, Map<String, dynamic>>(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
                itemBuilder: (context, item, index) => _buildDataRow(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
