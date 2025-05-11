import 'package:flutter/material.dart';
import 'package:fitwatch/loginPage.dart';
import 'package:fitwatch/registerPage.dart';
import 'package:fitwatch/profilePage.dart';
import 'package:fitwatch/profileSetUp.dart';
import 'package:fitwatch/home.dart';

void main() {
  runApp(MaterialApp(
    theme: ThemeData(useMaterial3: true),
    debugShowCheckedModeBanner: false,
    initialRoute: 'login',
    routes: {
      'login':(context) => Login(),
      'register':(context) => Register(),
      'profile':(context) => Profile(),
      'profileSetUp' : (context) => ProfileSetUp(),
      'home' : (context) => HomePage(),
      },
  ));
}
