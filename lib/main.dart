
import 'package:flutter/material.dart';
import 'ui/single_connect_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse Oximeter Connect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SingleConnectPage(title: 'Pulse Oximeter Connect App'),
    );
  }
}


