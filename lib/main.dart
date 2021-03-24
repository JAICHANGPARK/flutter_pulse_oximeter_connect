import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_pulse_oximeter_connect/enums/enum_detect.dart';
import 'package:flutter_pulse_oximeter_connect/service/pulse_oximeter/j1/j1_ble_gatt_service.dart';
import 'package:oscilloscope/oscilloscope.dart';
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
      home: MyHomePage(title: 'Pulse Oximeter Connect App'),
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

  BluetoothDevice? bluetoothDevice;
  StreamSubscription? deviceStateStreamSubscription;

  StreamSubscription? dataStateStreamSubscription0;
  StreamSubscription? dataStateStreamSubscription1;

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

  @override
  void dispose() {
    // TODO: implement dispose
    deviceStateStreamSubscription?.cancel();
    dataStateStreamSubscription0?.cancel();
    dataStateStreamSubscription1?.cancel();
    super.dispose();
  }
  String spo2Text = "";
  String heartText = "";
  String hrvText = "";
  String pIndexText = "";

  List<int> traceSine = [];

  @override
  Widget build(BuildContext context) {

    Oscilloscope scopeOne = Oscilloscope(
      showYAxis: true,
      yAxisColor: Colors.orange,
      margin: EdgeInsets.all(20.0),
      strokeWidth: 1.0,
      backgroundColor: Colors.black,
      traceColor: Colors.green,
      yAxisMax: 0,
      yAxisMin: 500000,
      dataSet: traceSine,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: StreamBuilder<List<ScanResult>>(
                  stream: FlutterBlue.instance.scanResults,
                  initialData: [],
                  builder: (c, snapshot) {
                    snapshot.data!.forEach((element) {
                      // print("${element.device.id} / ${element.device.name}");
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
              flex: 4,
              child: Column(
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          onPressed: bluetoothDevice == null
                              ? null
                              : () async {
                                  deviceStateStreamSubscription = bluetoothDevice?.state.listen((event) {
                                    if (BluetoothDeviceState.disconnected == event) {
                                      print("BluetoothDeviceState.disconnected");
                                    } else if (BluetoothDeviceState.connected == event) {
                                      print("BluetoothDeviceState.connected");
                                      setState(() {});
                                    }
                                  });
                                  await bluetoothDevice?.connect(autoConnect: false);
                                },
                          child: Text("Connected")),
                      ElevatedButton(
                          onPressed: () async {
                            await bluetoothDevice?.disconnect();
                            await dataStateStreamSubscription0?.cancel();
                            await dataStateStreamSubscription1?.cancel();
                          },
                          child: Text("DISCONNECT")),
                      ElevatedButton(
                          onPressed: bluetoothDevice == null
                              ? null
                              : () async {
                            List<BluetoothService> services = await bluetoothDevice!.discoverServices();
                            services.forEach((element) {
                              print("service: ${element.uuid.toString()}");
                              element.characteristics.forEach((element2) {
                                print("characteristics: ${element2.uuid.toString()}");
                                if (element2.uuid.toString() == J1BleGattService.UUID_CHAR_REQ_00) {
                                  requestBluetoothCharacteristic0 = element2;
                                } else if (element2.uuid.toString() == J1BleGattService.UUID_CHAR_DATA_00) {
                                  dataBluetoothCharacteristic0 = element2;
                                } else if (element2.uuid.toString() == J1BleGattService.UUID_CHAR_DATA_01) {
                                  dataBluetoothCharacteristic1 = element2;
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
                    ],
                  ),

                  Divider(color: Colors.grey,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          onPressed: () async {
                            await dataBluetoothCharacteristic0?.setNotifyValue(true);
                            await dataBluetoothCharacteristic1?.setNotifyValue(true);
                          },
                          child: Text("Set Listen")),
                      ElevatedButton(
                          onPressed: () async {
                            dataStateStreamSubscription0?.cancel();
                            dataStateStreamSubscription1?.cancel();

                            dataStateStreamSubscription0 = dataBluetoothCharacteristic0?.value.listen((event) {
                              print("dataBluetoothCharacteristic0");
                              print(event);
                              if(event.length > 0){
                                if(event[3] == EnumDetect.DETECTING.index){
                                  print(">>> Detacted");
                                  print("SPO2: ${event[4]}");
                                  print("Heart Rate: ${event[5]}");
                                  print("HRV: ${event[6]}");
                                  print("perfusionIndex: ${event[7] / 10.0}");
                                  setState(() {
                                    spo2Text = event[4].toString();
                                    heartText = event[5].toString();
                                    hrvText = event[6].toString();
                                    pIndexText = (event[7] / 10.0).toString();
                                  });

                                }
                              }


                            });
                            dataStateStreamSubscription1 = dataBluetoothCharacteristic1?.value.listen((event) {
                              print("dataBluetoothCharacteristic1");
                              print(event);
                              if(event.length> 0){
                                for(int i = 0; i < 5; i++){
                                  int j = i * 3;
                                  String s = "";
                                  s += event[j+3].toRadixString(16);
                                  s += event[j+4].toRadixString(16);
                                  s += event[j+5].toRadixString(16);
                                  // print(s);
                                  int adc = int.parse(s, radix: 16);
                                  print(adc);
                                  traceSine.add(adc);
                                }
                              }
                            });
                          },
                          child: Text("Set Subscribe")),
                    ],
                  ),
                  Divider(color: Colors.grey,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          onPressed: () async {
                            await requestBluetoothCharacteristic0?.write([
                              0x90,
                              0x01,
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
                          },
                          child: Text("Send Command 1")),
                      ElevatedButton(
                          onPressed: () async {
                            await requestBluetoothCharacteristic0?.write([
                              0x90,
                              0x01,
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
                          },
                          child: Text("Send Command 2")),


                    ],
                  ),
                  Divider(color: Colors.grey,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                          onPressed: () async {
                            await requestBluetoothCharacteristic0?.write([
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
                          },
                          child: Text("Start Read")),
                      ElevatedButton(
                          onPressed: () async {
                            await requestBluetoothCharacteristic0?.write([
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
                          },
                          child: Text("Stop Read")),
                    ],
                  ),

                  Divider(color: Colors.grey,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("Spo2 : $spo2Text %", style: TextStyle(
                        fontSize: 24
                      ),),
                      Text("Heart : $heartText Beats/min", style: TextStyle(
                          fontSize: 24
                      ),),
                    ],
                  ),
                  SizedBox(height: 24,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("HRV : $hrvText %", style: TextStyle(
                          fontSize: 24
                      ),),
                      Text("PI : $pIndexText %", style: TextStyle(
                          fontSize: 24
                      ),),
                    ],
                  ),
                  Expanded(flex: 1, child: scopeOne),

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
