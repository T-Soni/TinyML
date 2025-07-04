// import 'dart:collection';

// import 'package:flutter/material.dart';

// typedef MenuEntry = DropdownMenuEntry<String>;
// const List<String> list = <String>['Today', 'Last Week', 'Last Month'];

// class DropdownMenuWidget extends StatefulWidget {
//   const DropdownMenuWidget({super.key});

//   @override
//   State<DropdownMenuWidget> createState() => _DropdownMenuWidgetState();
// }

// class _DropdownMenuWidgetState extends State<DropdownMenuWidget> {
//   static final List<MenuEntry> menuEntries = UnmodifiableListView<MenuEntry>(
//     list.map<MenuEntry>((String name) => MenuEntry(value: name, label: name)),
//   );
//   String dropdownValue = list.first;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 40,
//       child: DropdownMenu<String>(
//         initialSelection: list.first,
//         onSelected: (String? value) {
//           // This is called when the user selects an item.
//           setState(() {
//             dropdownValue = value!;
//           });
//         },
//         dropdownMenuEntries: menuEntries,
//         menuStyle: MenuStyle(
//           padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 8)),
//           minimumSize: WidgetStateProperty.all(Size(100, 30)),
//         ),
//         textStyle: TextStyle(fontSize: 14),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

class DropdownMenuWidget extends StatefulWidget {
  const DropdownMenuWidget({super.key});

  @override
  State<DropdownMenuWidget> createState() => _DropdownMenuWidgetState();
}

class _DropdownMenuWidgetState extends State<DropdownMenuWidget> {
  final List<String> list = ['Today', 'Last Week', 'Last Month'];
  String dropdownValue = 'Today';

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
          value: dropdownValue,
          icon: const Icon(Icons.arrow_drop_down, size: 16),
          iconSize: 16,
          elevation: 2,
          style: const TextStyle(fontSize: 14, color: Colors.black),
          underline: SizedBox.shrink(),
          borderRadius: BorderRadius.circular(4),
          onChanged: (String? newValue) {
            setState(() {
              dropdownValue = newValue!;
            });
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
