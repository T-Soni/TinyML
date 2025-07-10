import 'package:flutter/material.dart';

class DropdownMenuWidget extends StatefulWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;
  const DropdownMenuWidget({
    super.key,
    this.selectedValue = 'Today',
    required this.onChanged,
  });

  @override
  State<DropdownMenuWidget> createState() => _DropdownMenuWidgetState();
}

class _DropdownMenuWidgetState extends State<DropdownMenuWidget> {
  final List<String> list = ['Today', 'Last Week', 'Last Month'];
  // String dropdownValue = 'Today';
  late String _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.selectedValue;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: BoxBorder.all(width: 1, color: Colors.black),
        ),
        child: DropdownButton<String>(
          value: _currentValue,
          icon: const Icon(Icons.arrow_drop_down, size: 16),
          iconSize: 16,
          elevation: 2,
          style: const TextStyle(fontSize: 14, color: Colors.black),
          underline: SizedBox.shrink(),
          borderRadius: BorderRadius.circular(4),
          onChanged: (String? newValue) {
            setState(() {
              _currentValue = newValue!;
            });
            widget.onChanged(newValue!);
          },
          items: list.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
        ),
      ),
    );
  }
}
