import 'package:flutter/material.dart';
import 'package:fitwatch/loginPage.dart';
import 'package:fitwatch/registerPage.dart';
import 'package:fitwatch/profilePage.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: 'login',
    routes: {
      'login':(context) => Login(),
      'register':(context) => Register(),
      'profile':(context) => Profile()
      },
  ));
}


// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// void main() => runApp(MyApp());

// class MyApp extends StatelessWidget {
//   Future<Map<String, dynamic>> fetchData() async {
//     final response = await http.get(
//       Uri.parse('http://192.168.255.202:8000/data'), // Replace with your laptop IP
//     );
//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception('Failed to load data');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: Text("ESP32 JSON Demo")),
//         body: FutureBuilder<Map<String, dynamic>>(
//           future: fetchData(),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting)
//               return Center(child: CircularProgressIndicator());
//             else if (snapshot.hasError)
//               return Center(child: Text("Error: ${snapshot.error}"));
//             else {
//               final data = snapshot.data!;
//               return Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text("Gyroscope X: ${data['gyroscope']['x']}"),
//                     Text("Gyroscope Y: ${data['gyroscope']['y']}"),
//                     Text("Gyroscope Z: ${data['gyroscope']['z']}"),
//                     SizedBox(height: 10),
//                     Text("Speed: ${data['speed']}"),
//                   ],
//                 ),
//               );
//             }
//           },
//         ),
//       ),
//     );
//   }
// }
