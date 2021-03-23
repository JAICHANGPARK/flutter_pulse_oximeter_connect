import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_pulse_oximeter_connect/service/pulse_oximeter/j1/j1_ble_gatt_service.dart';
import 'package:permission_handler/permission_handler.dart';

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
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {}

  BluetoothCharacteristic? requestBluetoothCharacteristic0;
  BluetoothCharacteristic? requestBluetoothCharacteristic1;
  BluetoothCharacteristic? dataBluetoothCharacteristic0;
  BluetoothCharacteristic? dataBluetoothCharacteristic1;

  checkSystemPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      await Permission.location.request();
      // We didn't ask for permission yet or the permission has been denied before but not permanently.
    }

// You can can also directly ask the permission about its status.
    if (await Permission.location.isRestricted) {
      // The OS restricts access, for example because of parental controls.
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkSystemPermission();
  }

  BluetoothDevice? bluetoothDevice;
  StreamSubscription? deviceStateStreamSubscription;

  @override
  void dispose() {
    // TODO: implement dispose
    deviceStateStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: StreamBuilder<List<ScanResult>>(
                  stream: FlutterBlue.instance.scanResults,
                  initialData: [],
                  builder: (c, snapshot) {
                    snapshot.data!.forEach((element) {
                      print("${element.device.id} / ${element.device.name}");
                      if (element.device.name == "J1") {
                        print(">>> Oximeter Founded!!");
                        bluetoothDevice = element.device;
                        FlutterBlue.instance.stopScan();
                      }
                    });
                    return ListTile();
                  }),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'You have pushed the button this many times:',
                  ),
                  Text(
                    '$_counter',
                    style: Theme.of(context).textTheme.headline4,
                  ),
                  ElevatedButton(
                      onPressed: bluetoothDevice == null
                          ? null
                          : () async {
                              deviceStateStreamSubscription = bluetoothDevice?.state.listen((event) {
                                if (BluetoothDeviceState.disconnected == event) {
                                  print("BluetoothDeviceState.disconnected");
                                } else if (BluetoothDeviceState.connected == event) {
                                  print("BluetoothDeviceState.connected");
                                  setState(() {
                                  });
                                }
                              });
                              await bluetoothDevice?.connect(autoConnect: false);
                            },
                      child: Text("Connected")),
                  ElevatedButton(
                      onPressed: bluetoothDevice == null
                          ? null
                          : () async {
                              List<BluetoothService> services = await bluetoothDevice!.discoverServices();
                              services.forEach((element) {
                                print("service: ${element.uuid.toString()}");
                                element.characteristics.forEach((element2) {
                                  print("characteristics: ${element2.uuid.toString()}");
                                  if(element2.uuid.toString() == J1BleGattService.UUID_CHAR_DATA_00){

                                  }
                                });
                              });
                            },
                      child: Text("Discovery")),
                  ElevatedButton(
                      onPressed: () async {
                        setState(() {});
                      },
                      child: Text("refresh")),
                  ElevatedButton(
                      onPressed: () async {
                        await bluetoothDevice?.disconnect();
                      },
                      child: Text("DISCONNECT")),
                  Divider(),

                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search), onPressed: () => FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
    );
  }
}
