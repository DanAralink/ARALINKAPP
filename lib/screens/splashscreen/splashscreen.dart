import 'dart:async';
import 'package:aralink_app/screens/getstarted/getstarted.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => GetstartedScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 253, 240, 3),
      body: Center(
        child: Image.asset(
          'assets/images/aralink-logo.png',
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}
