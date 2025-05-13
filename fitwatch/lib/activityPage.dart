import 'package:fitwatch/utilities/gradientButton.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnnotateActivity extends StatefulWidget {
  const AnnotateActivity({super.key});

  @override
  State<AnnotateActivity> createState() => _AnnotateActivityState();
}

class _AnnotateActivityState extends State<AnnotateActivity> {
  String? _selectedActivity;
  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(96, 181, 255, 1),
        title: const Text(
          'Activity',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          // Optional network status icon
          // Icon(
          //   _status == "Connected" ? Icons.wifi : Icons.wifi_off,
          //   color: _status == "Connected" ? Colors.green : Colors.red,
          // ),
        ],
      ),
      // backgroundColor: Colors.blue.shade50,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RaisedGradientButton(
                child: Text(
                  'WALKING',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
                gradient: LinearGradient(
                  colors: <Color>[Colors.blue, const Color.fromARGB(255, 9, 61, 104)],
                ),
                onPressed: () {
                  print('button clicked');
                }),
                const SizedBox(height: 10,),
            RaisedGradientButton(
                child: Text(
                  'WALKING UPSTAIRS',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
                gradient: LinearGradient(
                  colors: <Color>[Colors.green, const Color.fromARGB(255, 31, 96, 33)],
                ),
                onPressed: () {
                  print('button clicked');
                }),
                const SizedBox(height: 10,),
            RaisedGradientButton(
                child: Text(
                  'WALKING DOWNSTAIRS',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
                gradient: LinearGradient(
                  colors: <Color>[Colors.red, const Color.fromARGB(255, 131, 29, 22)],
                ),
                onPressed: () {
                  print('button clicked');
                }),
                const SizedBox(height: 10,),
            RaisedGradientButton(
                child: Text(
                  'SITTING',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
                gradient: LinearGradient(
                  colors: <Color>[Colors.amber, const Color.fromARGB(255, 136, 103, 5)],
                ),
                onPressed: () {
                  print('button clicked');
                }),
                const SizedBox(height: 10,),
            RaisedGradientButton(
                child: Text(
                  'STANDING',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
                gradient: LinearGradient(
                  colors: <Color>[Colors.orange, const Color.fromARGB(255, 130, 79, 1)],
                ),
                onPressed: () {
                  print('button clicked');
                }),
                const SizedBox(height: 10,),
            RaisedGradientButton(
                child: Text(
                  'LAYING',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
                gradient: LinearGradient(
                  colors: <Color>[Colors.deepPurple, const Color.fromARGB(255, 52, 23, 102)],
                ),
                onPressed: () {
                  print('button clicked');
                }),
                SizedBox(height: 30,),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, 'editProfile');
                              },
                              icon: Icon(Icons.start, color: Colors.white,),
                              label: Text("Start", style: TextStyle(color: Colors.white),),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromRGBO(96, 181, 255, 1),
                                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                            SizedBox(width: 10,),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, 'editProfile');
                              },
                              icon: Icon(Icons.stop, color: Colors.white,),
                              label: Text("Stop", style: TextStyle(color: Colors.white),),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromRGBO(96, 181, 255, 1),
                                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            )
                    ],
                  ),
                )
                
          ],
        ),
      ),
    );
  }

  Widget userData(String key, String value) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              key,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
