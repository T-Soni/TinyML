import 'package:flutter/material.dart';
import 'package:fitwatch/loginPage.dart';
import 'package:fitwatch/registerPage.dart';
import 'package:fitwatch/profilePage.dart';
import 'package:fitwatch/profileSetUp.dart';
import 'package:fitwatch/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getInitialRoute() async{
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if ((prefs.containsKey('uid')) && (prefs.containsKey('name')) && prefs.containsKey('age') && (prefs.containsKey('height')) && (prefs.containsKey('weight'))){
    return 'home';
  }
  else return 'login';
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  String initialScreen = await getInitialRoute();
  
  runApp(MaterialApp(
    theme: ThemeData(useMaterial3: true),
    debugShowCheckedModeBanner: false,
    initialRoute: initialScreen,
    // initialRoute: 'login',
    routes: {
      'login':(context) => Login(),
      'register':(context) => Register(),
      'profile':(context) => Profile(),
      'profileSetUp' : (context) => ProfileSetUp(),
      'home' : (context) => HomePage(),
      },
  ));
}
