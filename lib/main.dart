import 'dart:convert'; // for utf8
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class OBDApp extends StatefulWidget {
  @override
  _OBDAppState createState() => _OBDAppState();
}

class _OBDAppState extends State<OBDApp> {
  bool mockMode = true; // Toggle to enable or disable mock mode
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  String rpm = "0";

  @override
  void initState() {
    super.initState();
    if (mockMode) {
      simulateOBDData(); // Run mock data if mockMode is enabled
    } else {
      scanForDevices(); // Normal scan when not in mock mode
    }
  }

  void scanForDevices() {
    flutterBlue.startScan(timeout: Duration(seconds: 5));

    // Listen to scan results
    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        print('${r.device.name} found! rssi: ${r.rssi}');
        if (r.device.name == "Your ELM327 Device Name") {
          // Stop scanning once the device is found
          flutterBlue.stopScan();

          // Connect to the device
          connectToDevice(r.device);
        }
      }
    });
  }

  // Method to connect to a Bluetooth device
  void connectToDevice(BluetoothDevice device) async {
    print('Connecting to ${device.name}...');

    try {
      await device.connect();
      print('Connected to ${device.name}');

      // After connection, discover the services
      discoverServices(device);
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  // Discover services and characteristics
  void discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) {
      service.characteristics.forEach((characteristic) {
        if (characteristic.properties.write) {
          List<int> command = utf8.encode("010C\r"); // Example to get RPM
          characteristic.write(command);
        }
      });
    });
  }

  // Mock method to simulate OBD-II data
  void simulateOBDData() async {
    await Future.delayed(Duration(seconds: 2)); // Simulate scan delay
    print("MockELM327 connected!");

    // Simulate sending a command and receiving data
    simulateRPMResponse();
  }

  void simulateRPMResponse() {
    // Simulate receiving OBD-II data for RPM
    Future.delayed(Duration(seconds: 2), () {
      String hexResponse = "41 0C 1A F8"; // Simulated RPM response
      updateRPM(hexResponse);
    });
  }

  // Update RPM based on received data
  void updateRPM(String hexResponse) {
    // Assuming "41 0C 1A F8" response, extract "1A F8"
    if (hexResponse.length > 4) {
      String rpmHex = hexResponse.substring(4).replaceAll(' ', '');
      int rpmValue = int.parse(rpmHex, radix: 16);
      setState(() {
        rpm = (rpmValue / 4).toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OBD-II Data (Mock Mode)'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'RPM: $rpm',
              style: TextStyle(fontSize: 24),
            ),
            connectedDevice != null
                ? Text('Connected to: ${connectedDevice!.name}')
                : Text('Searching for ELM327...'),
          ],
        ),
      ),
    );
  }
}

void main() => runApp(MaterialApp(
  home: OBDApp(),
));
