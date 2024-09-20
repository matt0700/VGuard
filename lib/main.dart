import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:math'; // Import this for generating random numbers

void main() => runApp(MaterialApp(
  theme: ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.grey[900],
  ),
  home: OBDApp(),
));

class OBDApp extends StatefulWidget {
  @override
  _OBDAppState createState() => _OBDAppState();
}

class _OBDAppState extends State<OBDApp> {
  bool mockMode = true;
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  String rpm = "0";
  List<Map<String, String>> faultCodes = [];
  bool isSearching = false;

  List<String> dtcCommands = [
    "0300", // Powertrain
    "0301", // Chassis
    "0302", // Body
    "0303", // Network
  ];
  int currentDtcCommandIndex = 0;

  final Map<String, String> faultCodeMeanings = {
    "P0100": "Mass or Volume Air Flow Circuit Malfunction",
    "P0101": "Mass or Volume Air Flow Circuit Range/Performance Problem",
    "P0102": "Mass or Volume Air Flow Circuit Low Input",
    "P0103": "Mass or Volume Air Flow Circuit High Input",
    "P0104": "Mass or Volume Air Flow Circuit Intermittent",
    "P0105": "Manifold Absolute Pressure/Barometric Pressure Circuit Malfunction",
    "P0106": "Manifold Absolute Pressure/Barometric Pressure Circuit Range/Performance Problem",
    "P0107": "Manifold Absolute Pressure/Barometric Pressure Circuit Low Input",
    "P0108": "Manifold Absolute Pressure/Barometric Pressure Circuit High Input",
    "P0109": "Manifold Absolute Pressure/Barometric Pressure Circuit Intermittent",
    "P0110": "Intake Air Temperature Circuit Malfunction",
    // Add more P fault codes and their meanings as needed
    "P0111": "Intake Air Temperature Circuit Range/Performance Problem",
    "P0112": "Intake Air Temperature Circuit Low Input",
    "P0113": "Intake Air Temperature Circuit High Input",
    "P0114": "Intake Air Temperature Circuit Intermittent",
    "P0115": "Engine Coolant Temperature Circuit Malfunction",
    "P0116": "Engine Coolant Temperature Circuit Range/Performance Problem",
    "P0117": "Engine Coolant Temperature Circuit Low Input",
    "P0118": "Engine Coolant Temperature Circuit High Input",
    "P0119": "Engine Coolant Temperature Circuit Intermittent",
    "P0120": "Throttle/Pedal Position Sensor/Switch A Circuit Malfunction",
    // Add all other P fault codes as needed
  };

  @override
  void initState() {
    super.initState();
    if (mockMode) {
      simulateOBDData();
    } else {
      scanForDevices();
    }
  }

  void scanForDevices() {
    setState(() {
      isSearching = true;
    });
    flutterBlue.startScan(timeout: Duration(seconds: 5));
    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        print('${r.device.name} found! rssi: ${r.rssi}');
        if (r.device.name == "Your ELM327 Device Name") {
          flutterBlue.stopScan();
          connectToDevice(r.device);
        }
      }
    });
    Future.delayed(Duration(seconds: 5), () {
      setState(() {
        isSearching = false;
      });
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    print('Connecting to ${device.name}...');
    try {
      await device.connect();
      print('Connected to ${device.name}');
      setState(() {
        connectedDevice = device;
      });
      discoverServices(device);
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  void discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) {
      service.characteristics.forEach((characteristic) {
        if (characteristic.properties.write) {
          // Set up periodic RPM reading
          Timer.periodic(Duration(seconds: 2), (timer) {
            List<int> rpmCommand = utf8.encode("010C\r");
            characteristic.write(rpmCommand);
          });

          // Start DTC reading loop
          readNextDTC(characteristic);

          characteristic.value.listen((value) {
            String hexResponse = String.fromCharCodes(value);
            if (hexResponse.startsWith("41 0C")) {
              updateRPM(hexResponse);
            } else if (hexResponse.startsWith("43")) {
              updateDTC(hexResponse);
              // Read next DTC after processing the current one
              readNextDTC(characteristic);
            }
          });
        }
      });
    });
  }

  void readNextDTC(BluetoothCharacteristic characteristic) {
    if (currentDtcCommandIndex < dtcCommands.length) {
      List<int> dtcCommand = utf8.encode("${dtcCommands[currentDtcCommandIndex]}\r");
      characteristic.write(dtcCommand);
      currentDtcCommandIndex++;
    } else {
      // Reset index to start over after a delay
      currentDtcCommandIndex = 0;
      Future.delayed(Duration(seconds: 10), () {
        readNextDTC(characteristic);
      });
    }
  }

  void simulateOBDData() async {
    await Future.delayed(Duration(seconds: 2));
    print("MockELM327 connected!");
    setState(() {
      connectedDevice = null;
    });
    simulateRPMResponse();
    simulateDTCResponse();
  }

  void simulateRPMResponse() {
    Timer.periodic(Duration(seconds: 2), (timer) {
      String hexResponse = "41 0C ${(1000 + (DateTime.now().millisecondsSinceEpoch % 5000)).toRadixString(16).padLeft(4, '0')}";
      updateRPM(hexResponse);
    });
  }

 void simulateDTCResponse() {
  Timer.periodic(Duration(seconds: 10), (timer) {
    String hexResponse = generateRandomDTCResponse();
    updateDTC(hexResponse);
  });
}

String generateRandomDTCResponse() {
  Random random = Random();
  int numberOfCodes = random.nextInt(3) + 1; // Random number of DTCs (1 to 3)

  String dtcResponse = "43"; // Start with "43" (DTC response prefix)
  
  for (int i = 0; i < numberOfCodes; i++) {
    // Generate a random "P" fault code:
    // First character is always "P", then three hex digits
    String dtcCode = "P" +
        random.nextInt(10).toString() + // P0, P1, P2, etc.
        random.nextInt(16).toRadixString(16).toUpperCase() + // 0-9, A-F
        random.nextInt(256).toRadixString(16).padLeft(2, '0').toUpperCase(); // Two hex digits

    // Convert DTC code to hex byte format like real ELM327 data
    String byte1 = dtcCode.substring(1, 2) + dtcCode.substring(2, 3); // First two chars
    String byte2 = dtcCode.substring(3, 5); // Last two chars

    dtcResponse += " $byte1 $byte2";
  }

  return dtcResponse;
}
  void updateRPM(String hexResponse) {
    if (hexResponse.length > 4) {
      String rpmHex = hexResponse.substring(4).replaceAll(' ', '');
      int rpmValue = int.parse(rpmHex, radix: 16);
      setState(() {
        rpm = (rpmValue / 4).toString();
      });
    }
  }

void updateDTC(String hexResponse) {
  List<Map<String, String>> codes = [];
  if (hexResponse.startsWith("43")) {
    List<String> bytes = hexResponse.split(' ');
    for (int i = 1; i < bytes.length; i += 2) {
      if (bytes[i] != "00" || (i + 1 < bytes.length && bytes[i + 1] != "00")) {
        String dtcChar1 = _getDTCChar(int.parse(bytes[i][0], radix: 16));
        String dtcChar2 = bytes[i][1];
        String dtcChars34 = i + 1 < bytes.length ? bytes[i + 1] : "00";
        String fullCode = "$dtcChar1$dtcChar2$dtcChars34";

        // Check if the code starts with "P"
        if (fullCode.startsWith("P")) {
          String meaning = faultCodeMeanings[fullCode] ?? "Unknown fault code";
          codes.add({"code": fullCode, "meaning": meaning});
        }
      }
    }
  }
  setState(() {
    faultCodes = [...faultCodes, ...codes];
    // Remove duplicates
    faultCodes = faultCodes.toSet().toList();
  });
}

  String _getDTCChar(int value) {
    switch (value) {
      case 0: return "P0";
      case 1: return "P1";
      case 2: return "P2";
      case 3: return "P3";
      case 4: return "C0";
      case 5: return "C1";
      case 6: return "C2";
      case 7: return "C3";
      case 8: return "B0";
      case 9: return "B1";
      case 10: return "B2";
      case 11: return "B3";
      case 12: return "U0";
      case 13: return "U1";
      case 14: return "U2";
      case 15: return "U3";
      default: return "?";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(mockMode ? 'OBD-II Data (Mock Mode)' : 'OBD-II Data'),
        actions: [
          IconButton(
            icon: Icon(mockMode ? Icons.device_unknown : Icons.bluetooth),
            onPressed: () {
              setState(() {
                mockMode = !mockMode;
                faultCodes.clear();
              });
              if (mockMode) {
                simulateOBDData();
              } else {
                scanForDevices();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'RPM',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        rpm,
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Fault Codes:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              faultCodes.isEmpty
                  ? Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No fault codes found', style: TextStyle(fontSize: 18)),
                      ),
                    )
                  : Column(
                      children: faultCodes.map((codeMap) => Card(
                        margin: EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(codeMap['code']!, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(codeMap['meaning']!),
                        ),
                      )).toList(),
                    ),
              SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Connection Status:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        mockMode
                            ? 'Mock Device'
                            : (connectedDevice != null
                                ? connectedDevice!.name
                                : (isSearching ? 'Searching...' : 'Not Connected')),
                        style: TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: !mockMode ? FloatingActionButton(
        onPressed: scanForDevices,
        child: Icon(Icons.refresh),
        tooltip: 'Scan for devices',
      ) : null,
    );
  }
}