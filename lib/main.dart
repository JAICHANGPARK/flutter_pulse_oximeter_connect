import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_pulse_oximeter_connect/enums/enum_detect.dart';
import 'package:flutter_pulse_oximeter_connect/service/pulse_oximeter/j1/j1_ble_gatt_service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ui/oscilloscope.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Pulse Oximeter Connect App'),
    );
  }
}


