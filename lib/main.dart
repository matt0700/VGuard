import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:math';
import 'package:model_viewer_plus/model_viewer_plus.dart';

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
  Timer? mockDTCTimer;

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
    "P0121": "Throttle/Pedal Position Sensor/Switch A Circuit Range/Performance Problem",
    "P0122": "Throttle/Pedal Position Sensor/Switch A Circuit Low Input",
    "P0123": "Throttle/Pedal Position Sensor/Switch A Circuit High Input",
    "P0124": "Throttle/Pedal Position Sensor/Switch A Circuit Intermittent",
    "P0125": "Insufficient Coolant Temperature for Closed Loop Fuel Control",
    "P0126": "Insufficient Coolant Temperature for Stable Operation",
    "P0127": "Intake Air Temperature Too High",
    "P0128": "Coolant Thermostat (Coolant Temperature Below Thermostat Regulating Temperature)",
    "P0129": "Barometric Pressure Too Low",
    "P0130": "O2 Sensor Circuit Malfunction (Bank 1 Sensor 1)",
    "P0131": "O2 Sensor Circuit Low Voltage (Bank 1 Sensor 1)",
    "P0132": "O2 Sensor Circuit High Voltage (Bank 1 Sensor 1)",
    "P0133": "O2 Sensor Circuit Slow Response (Bank 1 Sensor 1)",
    "P0134": "O2 Sensor Circuit No Activity Detected (Bank 1 Sensor 1)",
    "P0135": "O2 Sensor Heater Circuit Malfunction (Bank 1 Sensor 1)",
    "P0136": "O2 Sensor Circuit Malfunction (Bank 1 Sensor 2)",
    "P0137": "O2 Sensor Circuit Low Voltage (Bank 1 Sensor 2)",
    "P0138": "O2 Sensor Circuit High Voltage (Bank 1 Sensor 2)",
    "P0139": "O2 Sensor Circuit Slow Response (Bank 1 Sensor 2)",
    "P0140": "O2 Sensor Circuit No Activity Detected (Bank 1 Sensor 2)",
    "P0141": "O2 Sensor Heater Circuit Malfunction (Bank 1 Sensor 2)",
    "P0142": "O2 Sensor Circuit Malfunction (Bank 1 Sensor 3)",
    "P0143": "O2 Sensor Circuit Low Voltage (Bank 1 Sensor 3)",
    "P0144": "O2 Sensor Circuit High Voltage (Bank 1 Sensor 3)",
    "P0145": "O2 Sensor Circuit Slow Response (Bank 1 Sensor 3)",
    "P0146": "O2 Sensor Circuit No Activity Detected (Bank 1 Sensor 3)",
    "P0147": "O2 Sensor Heater Circuit Malfunction (Bank 1 Sensor 3)",
    "P0148": "Fuel Delivery Error",
    "P0149": "Fuel Timing Error",
    "P0150": "O2 Sensor Circuit Malfunction (Bank 2 Sensor 1)",
    "P0151": "O2 Sensor Circuit Low Voltage (Bank 2 Sensor 1)",
    "P0152": "O2 Sensor Circuit High Voltage (Bank 2 Sensor 1)",
    "P0153": "O2 Sensor Circuit Slow Response (Bank 2 Sensor 1)",
    "P0154": "O2 Sensor Circuit No Activity Detected (Bank 2 Sensor 1)",
    "P0155": "O2 Sensor Heater Circuit Malfunction (Bank 2 Sensor 1)",
    "P0156": "O2 Sensor Circuit Malfunction (Bank 2 Sensor 2)",
    "P0157": "O2 Sensor Circuit Low Voltage (Bank 2 Sensor 2)",
    "P0158": "O2 Sensor Circuit High Voltage (Bank 2 Sensor 2)",
    "P0159": "O2 Sensor Circuit Slow Response (Bank 2 Sensor 2)",
    "P0160": "O2 Sensor Circuit No Activity Detected (Bank 2 Sensor 2)",
    "P0161": "O2 Sensor Heater Circuit Malfunction (Bank 2 Sensor 2)",
    "P0162": "O2 Sensor Circuit Malfunction (Bank 2 Sensor 3)",
    "P0163": "O2 Sensor Circuit Low Voltage (Bank 2 Sensor 3)",
    "P0164": "O2 Sensor Circuit High Voltage (Bank 2 Sensor 3)",
    "P0165": "O2 Sensor Circuit Slow Response (Bank 2 Sensor 3)",
    "P0166": "O2 Sensor Circuit No Activity Detected (Bank 2 Sensor 3)",
    "P0167": "O2 Sensor Heater Circuit Malfunction (Bank 2 Sensor 3)",
    "P0168": "Engine Coolant Temperature Too High",
    "P0169": "Incorrect Fuel Composition",
    "P0170": "Fuel Trim Malfunction (Bank 1)",
    "P0171": "System Too Lean (Bank 1)",
    "P0172": "System Too Rich (Bank 1)",
    "P0173": "Fuel Trim Malfunction (Bank 2)",
    "P0174": "System Too Lean (Bank 2)",
    "P0175": "System Too Rich (Bank 2)",
    "P0176": "Fuel Composition Sensor Circuit Malfunction",
    "P0177": "Fuel Composition Sensor Circuit Range/Performance",
    "P0178": "Fuel Composition Sensor Circuit Low Input",
    "P0179": "Fuel Composition Sensor Circuit High Input",
    "P0180": "Fuel Temperature Sensor A Circuit Malfunction",
    "P0181": "Fuel Temperature Sensor A Circuit Range/Performance",
    "P0182": "Fuel Temperature Sensor A Circuit Low Input",
    "P0183": "Fuel Temperature Sensor A Circuit High Input",
    "P0184": "Fuel Temperature Sensor A Circuit Intermittent",
    "P0185": "Fuel Temperature Sensor B Circuit Malfunction",
    "P0186": "Fuel Temperature Sensor B Circuit Range/Performance",
    "P0187": "Fuel Temperature Sensor B Circuit Low Input",
    "P0188": "Fuel Temperature Sensor B Circuit High Input",
    "P0189": "Fuel Temperature Sensor B Circuit Intermittent",
    "P0190": "Fuel Rail Pressure Sensor Circuit Malfunction",
    "P0191": "Fuel Rail Pressure Sensor Circuit Range/Performance",
    "P0192": "Fuel Rail Pressure Sensor Circuit Low Input",
    "P0193": "Fuel Rail Pressure Sensor Circuit High Input",
    "P0194": "Fuel Rail Pressure Sensor Circuit Intermittent",
    "P0195": "Engine Oil Temperature Sensor Malfunction",
    "P0196": "Engine Oil Temperature Sensor Range/Performance",
    "P0197": "Engine Oil Temperature Sensor Low",
    "P0198": "Engine Oil Temperature Sensor High",
    "P0199": "Engine Oil Temperature Sensor Intermittent",
    "P0200": "Injector Circuit Malfunction",
    "P0201": "Injector Circuit/Open - Cylinder 1",
    "P0202": "Injector Circuit/Open - Cylinder 2",
    "P0203": "Injector Circuit/Open - Cylinder 3",
    "P0204": "Injector Circuit/Open - Cylinder 4",
    "P0205": "Injector Circuit/Open - Cylinder 5",
    "P0206": "Injector Circuit/Open - Cylinder 6",
    "P0207": "Injector Circuit/Open - Cylinder 7",
    "P0208": "Injector Circuit/Open - Cylinder 8",
    "P0209": "Injector Circuit/Open - Cylinder 9",
    "P0210": "Injector Circuit/Open - Cylinder 10",
    "P0211": "Injector Circuit/Open - Cylinder 11",
    "P0212": "Injector Circuit/Open - Cylinder 12",
    "P0213": "Cold Start Injector 1 Malfunction",
    "P0214": "Cold Start Injector 2 Malfunction",
    "P0215": "Engine Shutoff Solenoid Malfunction",
    "P0216": "Injection Timing Control Circuit Malfunction",
    "P0217": "Engine Over Temperature Condition",
    "P0218": "Transmission Over Temperature Condition",
    "P0219": "Engine Overspeed Condition",
    "P0220": "Throttle/Pedal Position Sensor/Switch B Circuit Malfunction",
    "P0221": "Throttle/Pedal Position Sensor/Switch B Circuit Range/Performance Problem",
    "P0222": "Throttle/Pedal Position Sensor/Switch B Circuit Low Input",
    "P0223": "Throttle/Pedal Position Sensor/Switch B Circuit High Input",
    "P0224": "Throttle/Pedal Position Sensor/Switch B Circuit Intermittent",
    "P0225": "Throttle/Pedal Position Sensor/Switch C Circuit Malfunction",
    "P0226": "Throttle/Pedal Position Sensor/Switch C Circuit Range/Performance Problem",
    "P0227": "Throttle/Pedal Position Sensor/Switch C Circuit Low Input",
    "P0228": "Throttle/Pedal Position Sensor/Switch C Circuit High Input",
    "P0229": "Throttle/Pedal Position Sensor/Switch C Circuit Intermittent",
    "P0230": "Fuel Pump Primary Circuit Malfunction",
    "P0231": "Fuel Pump Secondary Circuit Low",
    "P0232": "Fuel Pump Secondary Circuit High",
    "P0233": "Fuel Pump Secondary Circuit Intermittent",
    "P0234": "Engine Overboost Condition",
    "P0235": "Turbocharger Boost Sensor A Circuit Malfunction",
    "P0236": "Turbocharger Boost Sensor A Circuit Range/Performance",
    "P0237": "Turbocharger Boost Sensor A Circuit Low",
    "P0238": "Turbocharger Boost Sensor A Circuit High",
    "P0239": "Turbocharger Boost Sensor B Circuit Malfunction",
    "P0240": "Turbocharger Boost Sensor B Circuit Range/Performance",
    "P0241": "Turbocharger Boost Sensor B Circuit Low",
    "P0242": "Turbocharger Boost Sensor B Circuit High",
    "P0243": "Turbocharger Wastegate Solenoid A Malfunction",
    "P0244": "Turbocharger Wastegate Solenoid A Range/Performance",
    "P0245": "Turbocharger Wastegate Solenoid A Low",
    "P0246": "Turbocharger Wastegate Solenoid A High",
    "P0247": "Turbocharger Wastegate Solenoid B Malfunction",
    "P0248": "Turbocharger Wastegate Solenoid B Range/Performance",
    "P0249": "Turbocharger Wastegate Solenoid B Low",
    "P0250": "Turbocharger Wastegate Solenoid B High",
    "P0251": "Injection Pump Fuel Metering Control A Malfunction (Cam/Rotor/Injector)",
    "P0252": "Injection Pump Fuel Metering Control A Range/Performance",
    "P0253": "Injection Pump Fuel Metering Control A Low",
    "P0254": "Injection Pump Fuel Metering Control A High",
    "P0255": "Injection Pump Fuel Metering Control A Intermittent",
    "P0256": "Injection Pump Fuel Metering Control B Malfunction (Cam/Rotor/Injector)",
    "P0257": "Injection Pump Fuel Metering Control B Range/Performance",
    "P0258": "Injection Pump Fuel Metering Control B Low",
    "P0259": "Injection Pump Fuel Metering Control B High",
    "P0260": "Injection Pump Fuel Metering Control B Intermittent",
    "P0261": "Cylinder 1 Injector Circuit Low",
    "P0262": "Cylinder 1 Injector Circuit High",
    "P0263": "Cylinder 1 Contribution/Balance Fault",
    "P0264": "Cylinder 2 Injector Circuit Low",
    "P0265": "Cylinder 2 Injector Circuit High",
    "P0266": "Cylinder 2 Contribution/Balance Fault",
    "P0267": "Cylinder 3 Injector Circuit Low",
    "P0268": "Cylinder 3 Injector Circuit High",
    "P0269": "Cylinder 3 Contribution/Balance Fault",
    "P0270": "Cylinder 4 Injector Circuit Low",
    "P0271": "Cylinder 4 Injector Circuit High",
    "P0272": "Cylinder 4 Contribution/Balance Fault",
    "P0273": "Cylinder 5 Injector Circuit Low",
    "P0274": "Cylinder 5 Injector Circuit High",
    "P0275": "Cylinder 5 Contribution/Balance Fault",
    "P0276": "Cylinder 6 Injector Circuit Low",
    "P0277": "Cylinder 6 Injector Circuit High",
    "P0278": "Cylinder 6 Contribution/Balance Fault",
    "P0279": "Cylinder 7 Injector Circuit Low",
    "P0280": "Cylinder 7 Injector Circuit High",
    "P0281": "Cylinder 7 Contribution/Balance Fault",
    "P0282": "Cylinder 8 Injector Circuit Low",
    "P0283": "Cylinder 8 Injector Circuit High",
    "P0284": "Cylinder 8 Contribution/Balance Fault",
    "P0285": "Cylinder 9 Injector Circuit Low",
    "P0286": "Cylinder 9 Injector Circuit High",
    "P0287": "Cylinder 9 Contribution/Balance Fault",
    "P0288": "Cylinder 10 Injector Circuit Low",
    "P0289": "Cylinder 10 Injector Circuit High",
    "P0290": "Cylinder 10 Contribution/Balance Fault",
    "P0291": "Cylinder 11 Injector Circuit Low",
    "P0292": "Cylinder 11 Injector Circuit High",
    "P0293": "Cylinder 11 Contribution/Balance Fault",
    "P0294": "Cylinder 12 Injector Circuit Low",
    "P0295": "Cylinder 12 Injector Circuit High",
    "P0296": "Cylinder 12 Contribution/Balance Fault",
    "P0297": "Vehicle Over Speed Condition",
    "P0298": "Engine Oil Over Temperature Condition",
    "P0299": "Turbocharger/Supercharger Underboost",
    "P0300": "Random/Multiple Cylinder Misfire Detected",
    "P0301": "Cylinder 1 Misfire Detected",
    "P0302": "Cylinder 2 Misfire Detected",
    "P0303": "Cylinder 3 Misfire Detected",
    "P0304": "Cylinder 4 Misfire Detected",
    "P0305": "Cylinder 5 Misfire Detected",
    "P0306": "Cylinder 6 Misfire Detected",
    "P0307": "Cylinder 7 Misfire Detected",
    "P0308": "Cylinder 8 Misfire Detected", 
    "P0309": "Cylinder 9 Misfire Detected",
    "P0310": "Cylinder 10 Misfire Detected",
    "P0311": "Cylinder 11 Misfire Detected",
    "P0312": "Cylinder 12 Misfire Detected",
    "P0313": "Misfire Detected with Low Fuel",
    "P0314": "Single Cylinder Misfire",
    "P0315": "Crankshaft Position System Variation Not Learned",
    "P0316": "Misfire Detected on Startup (First 1000 Revolutions)",
    "P0317": "Rough Road Hardware Not Present",
    "P0318": "Rough Road Sensor A Signal Circuit",
    "P0319": "Rough Road Sensor A Signal Circuit Range/Performance",
    "P0320": "Ignition/Distributor Engine Speed Input Circuit",
    "P0321": "Ignition/Distributor Engine Speed Input Circuit Range/Performance",
    "P0322": "Ignition/Distributor Engine Speed Input Circuit No Signal",
    "P0323": "Ignition/Distributor Engine Speed Input Circuit Intermittent",
    "P0324": "Knock Control System Error",
    "P0325": "Knock Sensor 1 Circuit Malfunction (Bank 1 or Single Sensor)",
    "P0326": "Knock Sensor 1 Circuit Range/Performance (Bank 1 or Single Sensor)",
    "P0327": "Knock Sensor 1 Circuit Low Input (Bank 1 or Single Sensor)",
    "P0328": "Knock Sensor 1 Circuit High Input (Bank 1 or Single Sensor)",
    "P0329": "Knock Sensor 1 Circuit Intermittent (Bank 1 or Single Sensor)",
    "P0330": "Knock Sensor 2 Circuit Malfunction (Bank 2)",
    "P0331": "Knock Sensor 2 Circuit Range/Performance (Bank 2)",
    "P0332": "Knock Sensor 2 Circuit Low Input (Bank 2)",
    "P0333": "Knock Sensor 2 Circuit High Input (Bank 2)",
    "P0334": "Knock Sensor 2 Circuit Intermittent (Bank 2)",
    "P0335": "Crankshaft Position Sensor A Circuit Malfunction",
    "P0336": "Crankshaft Position Sensor A Circuit Range/Performance",
    "P0337": "Crankshaft Position Sensor A Circuit Low Input",
    "P0338": "Crankshaft Position Sensor A Circuit High Input",
    "P0339": "Crankshaft Position Sensor A Circuit Intermittent",
    "P0340": "Camshaft Position Sensor A Circuit Malfunction (Bank 1 or Single Sensor)",
    "P0341": "Camshaft Position Sensor A Circuit Range/Performance (Bank 1 or Single Sensor)",
    "P0342": "Camshaft Position Sensor A Circuit Low Input (Bank 1 or Single Sensor)",
    "P0343": "Camshaft Position Sensor A Circuit High Input (Bank 1 or Single Sensor)",
    "P0344": "Camshaft Position Sensor A Circuit Intermittent (Bank 1 or Single Sensor)",
    "P0345": "Camshaft Position Sensor A Circuit Malfunction (Bank 2)",
    "P0346": "Camshaft Position Sensor A Circuit Range/Performance (Bank 2)",
    "P0347": "Camshaft Position Sensor A Circuit Low Input (Bank 2)",
    "P0348": "Camshaft Position Sensor A Circuit High Input (Bank 2)",
    "P0349": "Camshaft Position Sensor A Circuit Intermittent (Bank 2)",
    "P0350": "Ignition Coil Primary/Secondary Circuit Malfunction",
    "P0351": "Ignition Coil A Primary/Secondary Circuit Malfunction",
    "P0352": "Ignition Coil B Primary/Secondary Circuit Malfunction",
    "P0353": "Ignition Coil C Primary/Secondary Circuit Malfunction",
    "P0354": "Ignition Coil D Primary/Secondary Circuit Malfunction",
    "P0355": "Ignition Coil E Primary/Secondary Circuit Malfunction",
    "P0356": "Ignition Coil F Primary/Secondary Circuit Malfunction",
    "P0357": "Ignition Coil G Primary/Secondary Circuit Malfunction",
    "P0358": "Ignition Coil H Primary/Secondary Circuit Malfunction",
    "P0359": "Ignition Coil I Primary/Secondary Circuit Malfunction",
    "P0360": "Ignition Coil J Primary/Secondary Circuit Malfunction",
    "P0361": "Ignition Coil K Primary/Secondary Circuit Malfunction",
    "P0362": "Ignition Coil L Primary/Secondary Circuit Malfunction",
    "P0370": "Timing Reference High Resolution Signal A Malfunction",
    "P0371": "Timing Reference High Resolution Signal A Too Many Pulses",
    "P0372": "Timing Reference High Resolution Signal A Too Few Pulses",
    "P0373": "Timing Reference High Resolution Signal A Intermittent/Erratic Pulses",
    "P0374": "Timing Reference High Resolution Signal A No Pulses",
    "P0380": "Glow Plug/Heater Circuit A Malfunction",
    "P0381": "Glow Plug/Heater Indicator Circuit Malfunction",
    "P0382": "Glow Plug/Heater Circuit B Malfunction",
    "P0385": "Crankshaft Position Sensor B Circuit Malfunction",
    "P0386": "Crankshaft Position Sensor B Circuit Range/Performance",
    "P0387": "Crankshaft Position Sensor B Circuit Low Input",
    "P0388": "Crankshaft Position Sensor B Circuit High Input",
    "P0389": "Crankshaft Position Sensor B Circuit Intermittent",
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
          Timer.periodic(Duration(seconds: 2), (timer) {
            List<int> rpmCommand = utf8.encode("010C\r");
            characteristic.write(rpmCommand);
          });

          readNextDTC(characteristic);

          characteristic.value.listen((value) {
            String hexResponse = String.fromCharCodes(value);
            if (hexResponse.startsWith("41 0C")) {
              updateRPM(hexResponse);
            } else if (hexResponse.startsWith("43")) {
              updateDTC(hexResponse);
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
    startMockDTCSimulation();
  }

  void simulateRPMResponse() {
    Timer.periodic(Duration(seconds: 2), (timer) {
      String hexResponse = "41 0C ${(1000 + (DateTime.now().millisecondsSinceEpoch % 5000)).toRadixString(16).padLeft(4, '0')}";
      updateRPM(hexResponse);
    });
  }

  void startMockDTCSimulation() {
    mockDTCTimer?.cancel();
    mockDTCTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (mockMode) {
        String hexResponse = generateRandomDTCResponse();
        updateDTC(hexResponse);
      } else {
        timer.cancel();
      }
    });
  }

  void stopMockDTCSimulation() {
    mockDTCTimer?.cancel();
    mockDTCTimer = null;
  }

 String generateRandomDTCResponse() {
    Random random = Random();
    int numberOfCodes = random.nextInt(3) + 1; // Generate 1 to 3 codes

    String dtcResponse = "43";
    
    for (int i = 0; i < numberOfCodes; i++) {
      // Generate a random "P" fault code between P0100 and P0200
      int codeNumber = random.nextInt(101) + 100; // 100 to 200
      String dtcCode = "P0" + codeNumber.toString();

      // Convert to the format expected by the OBD-II protocol
      int firstByte = int.parse(dtcCode.substring(1, 3), radix: 16);
      int secondByte = int.parse(dtcCode.substring(3, 5), radix: 16);

      dtcResponse += " ${firstByte.toRadixString(16).padLeft(2, '0')} ${secondByte.toRadixString(16).padLeft(2, '0')}";
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
        if (i + 1 < bytes.length) {
          String dtcChar1 = _getDTCChar(int.parse(bytes[i][0], radix: 16));
          String dtcChar2 = bytes[i][1];
          String dtcChars34 = bytes[i + 1];
          String fullCode = "$dtcChar1$dtcChar2$dtcChars34";

          String meaning = faultCodeMeanings[fullCode] ?? "Unknown fault code";
          codes.add({"code": fullCode, "meaning": meaning});
        }
      }
    }
    setState(() {
      faultCodes = codes; // Replace existing codes instead of appending
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
  Widget build3DCarModel() {
  return Container(
    height: 300,
    child: ModelViewer(
      src: 'assets/Mercedes+Benz+GLS+580.glb',
      alt: "A 3D model of a Mercedes Benz GLS 580",
      ar: true,
      autoRotate: true,
      cameraControls: true,
    ),
  );
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
                stopMockDTCSimulation();
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
                '3D Car Model:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              build3DCarModel(),
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
  @override
  void dispose() {
    stopMockDTCSimulation();
    super.dispose();
  }
}