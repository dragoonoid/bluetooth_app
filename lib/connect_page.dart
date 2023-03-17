
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({Key? key}) : super(key: key);

  @override
  BluetoothPageState createState() => BluetoothPageState();
}

class BluetoothPageState extends State<BluetoothPage> {
  BluetoothConnection? connection;
  bool isConnecting = true;
  bool get isConnected => connection != null && connection!.isConnected;
  bool isDisconnecting = false;
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    connectToDevice();
  }

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection!.dispose();
      connection = null;
    }
    super.dispose();
  }

  void connectToDevice() async {
    BluetoothDevice device = await FlutterBluetoothSerial.instance
        .getBondedDevices()
        .then((devices) => devices.firstWhere((device) => device.name == 'HC05',
            orElse: () {}));
    if (device != null) {
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);
      setState(() {
        this.connection = connection;
        isConnecting = false;
      });
      listenForData();
    }
  }

  void listenForData() {
    connection!.input!.listen((Uint8List data) {
      String message = String.fromCharCodes(data);
      print(message);
    }).onDone(() {
      if (!isDisconnecting) {
        print('Disconnected by remote request');
      }
    });
  }

  void sendData(String data) async {
    try {
      connection!.output.add(Uint8List.fromList(data.codeUnits));
      await connection!.output.allSent;
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth Page')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
              'Connection Status: ${isConnected ? "Connected" : "Disconnected"}'),
          SizedBox(height: 20),
          isConnecting ? CircularProgressIndicator() : SizedBox(),
          SizedBox(height: 20),
          TextField(
            controller: textEditingController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Enter a message to send',
            ),
          ),
          SizedBox(height: 20),
          RaisedButton(
            child: Text('Send'),
            onPressed: isConnected
                ? () {
                    sendData(textEditingController.text);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
