import 'package:flutter/material.dart';

class MultiConnectPage extends StatefulWidget {
  MultiConnectPage({Key? key}) : super(key: key);

  @override
  _MultiConnectPageState createState() => _MultiConnectPageState();
}

class _MultiConnectPageState extends State<MultiConnectPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Multi-Connect"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(onPressed: (){}, child: Text("Start Scan")),
              ],
            )
          ],
        ),
      ),
    );
  }
}