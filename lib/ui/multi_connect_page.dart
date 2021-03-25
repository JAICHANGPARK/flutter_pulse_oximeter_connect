import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_pulse_oximeter_connect/service/pulse_oximeter/j1/j1_ble_gatt_service.dart';

class J1Device {
  BluetoothDevice? bluetoothDevice;
  BluetoothCharacteristic? requestBluetoothCharacteristic0;
  BluetoothCharacteristic? requestBluetoothCharacteristic1;
  BluetoothCharacteristic? dataBluetoothCharacteristic0;
  BluetoothCharacteristic? dataBluetoothCharacteristic1;
  StreamSubscription? deviceStateStreamSubscription;

  J1Device(
      {this.bluetoothDevice,
      this.requestBluetoothCharacteristic0,
      this.requestBluetoothCharacteristic1,
      this.dataBluetoothCharacteristic0,
      this.dataBluetoothCharacteristic1});
}

class MultiConnectPage extends StatefulWidget {
  MultiConnectPage({Key? key}) : super(key: key);

  @override
  _MultiConnectPageState createState() => _MultiConnectPageState();
}

class _MultiConnectPageState extends State<MultiConnectPage> {
  StreamSubscription? scanStreamSubscription;
  Map<String, J1Device> bluetoothDevices = Map();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    scanStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Multi-Connect"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton(
                    onPressed: () async {
                      bluetoothDevices.clear();
                      scanStreamSubscription = FlutterBlue.instance
                          .scan(
                        timeout: Duration(seconds: 10),
                      )
                          .listen((event) {
                        print("${event.device.name} / ${event.device.id}");
                        if (event.device.name == "J1") {
                          print(">>> J1 Detected ");
                          bluetoothDevices["${event.device.id}"] = J1Device(bluetoothDevice: event.device);
                        }
                      });
                    },
                    child: Text("Start Scan")),
                SizedBox(
                  width: 24,
                ),
                ElevatedButton(
                    onPressed: () async {
                      await scanStreamSubscription?.cancel();
                      await FlutterBlue.instance.stopScan();
                    },
                    child: Text("Stop Scan")),
              ],
            ),
            ElevatedButton(
                onPressed: () async {
                  print(">>> bluetoothDevices.length : ${bluetoothDevices.length}");
                },
                child: Text("Check Devices")),
            ElevatedButton(
                onPressed: () async {
                  // print(">>> bluetoothDevices.length : ${bluetoothDevices.length}");
                  bluetoothDevices.forEach((key, value) async {
                    print(key);
                    await value.bluetoothDevice?.connect(autoConnect: false, timeout: Duration(seconds: 10));
                  });
                },
                child: Text("Connect Devices")),
            ElevatedButton(
                onPressed: () async {
                  // print(">>> bluetoothDevices.length : ${bluetoothDevices.length}");
                  bluetoothDevices.forEach((key, value) async {
                    print(key);
                    List<BluetoothService>? services = await value.bluetoothDevice?.discoverServices();
                    services?.forEach((element) {
                      print("service: ${element.uuid.toString()}");
                      element.characteristics.forEach((element2) {
                        print("characteristics: ${element2.uuid.toString()}");
                        if (element2.uuid.toString() == J1BleGattService.UUID_CHAR_REQ_00) {
                          value.requestBluetoothCharacteristic0 = element2;
                        } else if (element2.uuid.toString() == J1BleGattService.UUID_CHAR_DATA_00) {
                          value.dataBluetoothCharacteristic0 = element2;
                        } else if (element2.uuid.toString() == J1BleGattService.UUID_CHAR_DATA_01) {
                          value.dataBluetoothCharacteristic1 = element2;
                        }
                      });
                    });
                  });
                },
                child: Text(" Discovery Services")),
            ElevatedButton(
                onPressed: () async {
                  // print(">>> bluetoothDevices.length : ${bluetoothDevices.length}");
                  bluetoothDevices.forEach((key, value) async {
                    print(key);
                    await value.dataBluetoothCharacteristic0?.setNotifyValue(true);
                    await value.dataBluetoothCharacteristic1?.setNotifyValue(true);
                  });
                },
                child: Text("Set Notify Enable")),
            ElevatedButton(
                onPressed: () async {
                  // print(">>> bluetoothDevices.length : ${bluetoothDevices.length}");
                  bluetoothDevices.forEach((key, value) async {
                    print(key);
                    await value.bluetoothDevice?.disconnect();
                  });
                },
                child: Text(" Disconnect Devices")),

          ],
        ),
      ),
    );
  }
}
