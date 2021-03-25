import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_pulse_oximeter_connect/enums/enum_detect.dart';
import 'package:flutter_pulse_oximeter_connect/service/pulse_oximeter/j1/j1_ble_gatt_service.dart';

class J1Device {
  BluetoothDevice? bluetoothDevice;
  BluetoothCharacteristic? requestBluetoothCharacteristic0;
  BluetoothCharacteristic? requestBluetoothCharacteristic1;
  BluetoothCharacteristic? dataBluetoothCharacteristic0;
  BluetoothCharacteristic? dataBluetoothCharacteristic1;

  J1Device(
      {this.bluetoothDevice,
      this.requestBluetoothCharacteristic0,
      this.requestBluetoothCharacteristic1,
      this.dataBluetoothCharacteristic0,
      this.dataBluetoothCharacteristic1});
}

class OximeterData{
  int hr;
  int spo2;
  int hrv;
  double pi;
  int timestamp;
  OximeterData( this.spo2, this.hr, this.hrv, this.pi, this.timestamp);
}

class MultiConnectPage extends StatefulWidget {
  MultiConnectPage({Key? key}) : super(key: key);

  @override
  _MultiConnectPageState createState() => _MultiConnectPageState();
}

class _MultiConnectPageState extends State<MultiConnectPage> {
  StreamSubscription? scanStreamSubscription;
  Map<String, J1Device> bluetoothDevices = Map();
  List<StreamSubscription> deviceStateStreamSubscriptions = [];
  List<StreamSubscription> dataStateStreamSubscriptions = [];
  List<Widget> deviceItems = [];
  List<OximeterData> oximeterDatas = [];
  ScrollController _scrollController = new ScrollController();
    Timer? scrollTimer ;
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
                    deviceStateStreamSubscriptions.add(value.bluetoothDevice!.state.listen((event) {
                      print(">>>deviceStateStreamSubscriptions key: $key");
                      if (event == BluetoothDeviceState.disconnected) {
                        print(">>> $key : disconnected");
                      } else if (event == BluetoothDeviceState.connected) {
                        print(">>> $key : connected");
                      }
                    }));

                    await value.bluetoothDevice?.connect(autoConnect: false, timeout: Duration(seconds: 10));
                    deviceItems.add(ListTile(
                      title: Text("${value.bluetoothDevice?.name}"),
                      subtitle: Text("${value.bluetoothDevice?.id}"),
                    ));
                    setState(() {});
                  });
                  setState(() {});
                },
                child: Text("Connect Devices")),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "연결된 장치",
                style: TextStyle(fontSize: 18),
              ),
            ),
            Container(
              height: 240,
              child: deviceItems.length > 0
                  ? ListView.builder(
                      itemBuilder: (context, index) {
                        return deviceItems[index];
                      },
                      itemCount: deviceItems.length,
                    )
                  : Text("연결된 장치 없음"),
            ),
            Divider(
              color: Colors.grey,
            ),
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

                    dataStateStreamSubscriptions.add(value.dataBluetoothCharacteristic0!.value.listen((event) {
                      print("dataBluetoothCharacteristic0");
                      print(event);
                      if (event.length > 0) {
                        if (event[3] == EnumDetect.DETECTING.index) {
                          print(
                              ">>> $key -> Detacted: SPO2: ${event[4]} | Heart Rate: ${event[5]} | HRV: ${event[6]} | perfusionIndex: ${event[7] / 10.0}");

                          setState(() {
                            oximeterDatas.add(OximeterData(event[4], event[5], event[6], event[7] / 10.0, DateTime.now().millisecondsSinceEpoch));
                          });
                          // setState(() {
                          //   spo2Text = event[4].toString();
                          //   heartText = event[5].toString();
                          //   hrvText = event[6].toString();
                          //   pIndexText = (event[7] / 10.0).toString();
                          // });
                        }
                      }
                    }));
                  });
                },
                child: Text("Set Listen ")),
            Divider(
              color: Colors.grey,
            ),
            Row(
              children: [
                ElevatedButton(
                    onPressed: () async {
                      // print(">>> bluetoothDevices.length : ${bluetoothDevices.length}");
                      bluetoothDevices.forEach((key, value) async {
                        print(key);
                        await value.requestBluetoothCharacteristic0?.write([
                          0x90,
                          0x02,
                          0x01,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00
                        ]);
                      });

                      scrollTimer = Timer(
                        Duration(seconds: 1),
                            () {
                              _scrollController.animateTo(
                                0.0,
                                curve: Curves.easeOut,
                                duration: const Duration(milliseconds: 300),
                              );
                            }
                      );
                    },
                    child: Text("Start Data Receive")),
                SizedBox(
                  width: 24,
                ),
                ElevatedButton(
                    onPressed: () async {
                      // print(">>> bluetoothDevices.length : ${bluetoothDevices.length}");
                      bluetoothDevices.forEach((key, value) async {
                        print(key);
                        await value.requestBluetoothCharacteristic0?.write([
                          0x90,
                          0x02,
                          0x02,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00,
                          0x00
                        ]);
                      });
                      scrollTimer?.cancel();
                    },
                    child: Text("Stop Data Receive")),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "데이터 펍",
                style: TextStyle(fontSize: 18),
              ),
            ),
            Container(height: 240,
            child: ListView.builder(
                controller: _scrollController,
              reverse: true,
                itemCount: oximeterDatas.length,
                itemBuilder: (context, index){
              return ListTile(
                title: Text("${oximeterDatas[index].hr}bpm, ${oximeterDatas[index].spo2}%, ${oximeterDatas[index].timestamp}"),
              );
            }),),
            Divider(
              color: Colors.grey,
            ),
            ElevatedButton(
                onPressed: () async {
                  // print(">>> bluetoothDevices.length : ${bluetoothDevices.length}");
                  bluetoothDevices.forEach((key, value) async {
                    print(key);
                    await value.bluetoothDevice?.disconnect();
                  });

                  deviceStateStreamSubscriptions.forEach((element) {
                    element.cancel();
                  });
                  dataStateStreamSubscriptions.forEach((element) {
                    element.cancel();
                  });
                  
                  scrollTimer?.cancel();

                  setState(() {
                    deviceItems.clear();
                    oximeterDatas.clear();
                  });
                },
                child: Text(" Disconnect Devices")),
          ],
        ),
      ),
    );
  }
}
