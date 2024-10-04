import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:math' as math;
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_cube/flutter_cube.dart';

void main() => runApp(MaterialApp(
  theme: ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.grey[900],
  ),
  home: OBDApp(),
));

class CarIndicator extends StatefulWidget {
  final String affectedPart;
  final Color primaryColor;
  final Color accentColor;

  CarIndicator({
    required this.affectedPart,
    this.primaryColor = Colors.white,
    this.accentColor = Colors.red,
  });

  @override
  _CarIndicatorState createState() => _CarIndicatorState();
}

class _CarIndicatorState extends State<CarIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final aspectRatio = 300 / 200; // Adjust this based on your car design
        final width = constraints.maxWidth;
        final height = width / aspectRatio;

        return Column(
          children: [
            SizedBox(
              width: width,
              height: height,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(width, height),
                    painter: ModernCarPainter(
                      affectedPart: widget.affectedPart,
                      animationValue: _animation.value,
                      primaryColor: widget.primaryColor,
                      accentColor: widget.accentColor,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ['Body', 'Engine', 'Chassis', 'Network'].map((part) {
                return _buildLegendItem(part);
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(String part) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          color: part == widget.affectedPart ? widget.accentColor : widget.primaryColor,
        ),
        SizedBox(width: 5),
        Text(part, style: TextStyle(color: widget.primaryColor)),
      ],
    );
  }
}

class ModernCarPainter extends CustomPainter {
  final String affectedPart;
  final double animationValue;
  final Color primaryColor;
  final Color accentColor;

  ModernCarPainter({
    required this.affectedPart,
    required this.animationValue,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = primaryColor;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accentColor.withOpacity(animationValue * 0.5);

    final scale = size.width / 300;
    canvas.scale(scale);

    // Car body
    final bodyPath = Path()
      ..moveTo(30, 140)
      ..lineTo(60, 140)
      ..quadraticBezierTo(80, 140, 90, 120)
      ..lineTo(110, 80)
      ..quadraticBezierTo(150, 60, 190, 80)
      ..lineTo(210, 120)
      ..quadraticBezierTo(220, 140, 240, 140)
      ..lineTo(270, 140)
      ..quadraticBezierTo(280, 140, 280, 130)
      ..lineTo(280, 110)
      ..quadraticBezierTo(280, 100, 270, 100)
      ..lineTo(250, 100)
      ..lineTo(230, 60)
      ..quadraticBezierTo(150, 40, 70, 60)
      ..lineTo(50, 100)
      ..lineTo(30, 100)
      ..quadraticBezierTo(20, 100, 20, 110)
      ..lineTo(20, 130)
      ..quadraticBezierTo(20, 140, 30, 140);

    if (affectedPart == 'Body') {
      canvas.drawPath(bodyPath, fillPaint);
    }
    canvas.drawPath(bodyPath, paint);

    // Wheels
    _drawWheel(canvas, Offset(80, 140), paint);
    _drawWheel(canvas, Offset(220, 140), paint);

    // Windows
    final windowPath = Path()
      ..moveTo(100, 80)
      ..lineTo(120, 80)
      ..lineTo(140, 65)
      ..lineTo(160, 65)
      ..lineTo(180, 80)
      ..lineTo(200, 80);
    canvas.drawPath(windowPath, paint);

    // Engine area
    final enginePath = Path()
      ..moveTo(30, 100)
      ..lineTo(90, 100)
      ..lineTo(90, 120)
      ..lineTo(30, 120)
      ..close();
    if (affectedPart == 'Engine') {
      canvas.drawPath(enginePath, fillPaint);
    }
    canvas.drawPath(enginePath, paint);

    // Chassis area
    final chassisPath = Path()
      ..moveTo(100, 130)
      ..lineTo(200, 130)
      ..lineTo(200, 140)
      ..lineTo(100, 140)
      ..close();
    if (affectedPart == 'Chassis') {
      canvas.drawPath(chassisPath, fillPaint);
    }
    canvas.drawPath(chassisPath, paint);

    // Network area (roof)
    final networkPath = Path()
      ..moveTo(120, 80)
      ..lineTo(140, 65)
      ..lineTo(160, 65)
      ..lineTo(180, 80)
      ..close();
    if (affectedPart == 'Network') {
      canvas.drawPath(networkPath, fillPaint);
    }
    canvas.drawPath(networkPath, paint);

    // Headlights
    canvas.drawCircle(Offset(40, 110), 5, paint);
    canvas.drawCircle(Offset(260, 110), 5, paint);

    // Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Affected: $affectedPart',
        style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(150 - textPainter.width / 2, 170));
  }

  void _drawWheel(Canvas canvas, Offset center, Paint paint) {
    canvas.drawCircle(center, 25, paint);
    canvas.drawCircle(center, 15, paint);
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        center + Offset(15 * math.cos(angle), 15 * math.sin(angle)),
        center + Offset(25 * math.cos(angle), 25 * math.sin(angle)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
class OBDApp extends StatefulWidget {
  @override
  _OBDAppState createState() => _OBDAppState();
}

class _OBDAppState extends State<OBDApp> {
  int _currentIndex = 0;

  // Add CameraPage to the list of pages
  final List<Widget> _pages = [
    HomePage(),
    ScannerPage(),
    CameraPage(), // New Camera Page added here
    AboutUsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vguard'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('App Information'),
                    content: Text('This app provides OBD-II diagnostics for your vehicle.'),
                    actions: [
                      TextButton(
                        child: Text('Close'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70, // Slightly dimmed for unselected
        backgroundColor: Theme.of(context).primaryColor, // Set background to match AppBar
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.scanner),
            label: 'Diagnose',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt), // Use a camera icon
            label: 'Camera', // Add a label for Camera
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'About Us',
          ),
        ],
      ),
    );
  }
}
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,  
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue,  
              shape: BoxShape.circle, 
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),  
              child: Image.asset(
                'assets/vguard-logo.png',
                fit: BoxFit.contain,  
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Welcome to Vguard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class ScannerPage extends StatefulWidget {
  @override
  _ScannerPageState createState() => _ScannerPageState();
}



class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _picker = ImagePicker();

  // Map to hold the selected images for each vehicle part
  Map<String, XFile?> _imageFileMap = {
    'hood': null,
    'left_side': null,
    'right_side': null,
    'back': null,
    'front': null,
    'roof': null,
  };

  // Roboflow API setup
  final String apiKey = "fDWVFYW47OqG3Dj3LGkF"; // Replace with your API key
  final String modelId = "cypres/exterior-damage-detection/3"; // Replace with your model ID
  final String apiUrl =
      "https://detect.roboflow.com/cypres/exterior-damage-detection/3?api_key=fDWVFYW47OqG3Dj3LGkF";

  // Function to pick image for a particular part
  Future<void> _pickImage(String part) async {
    final XFile? selectedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFileMap[part] = selectedImage;
    });
  }

  // Check if all images for all parts are uploaded
  bool _areAllImagesUploaded() {
    return !_imageFileMap.values.any((image) => image == null);
  }

  // Function to send an image to the Roboflow API and get predictions
  Future<Map<String, dynamic>> _getInference(XFile imageFile) async {
    final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await http.Response.fromStream(response);
      return jsonDecode(responseData.body); // Return the parsed response data
    } else {
      throw Exception("Failed to get prediction from Roboflow: ${response.statusCode}");
    }
  }

  // Handle the logic when the 'Generate 3D Model' button is pressed
  void _generate3DModel() async {
    if (_areAllImagesUploaded()) {
      // Send each image to Roboflow for inference
      for (var part in _imageFileMap.keys) {
        if (_imageFileMap[part] != null) {
          try {
            var result = await _getInference(_imageFileMap[part]!);
            print("Prediction for $part: $result");
            // Here, you can parse the result and process the 3D model accordingly
            // For instance, store the predictions for later visualization
          } catch (e) {
            print("Error getting inference: $e");
          }
        }
      }

      // After processing all images, navigate to 3D model page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ModelPage(imageFiles: _imageFileMap),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload images for all parts of the vehicle.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Vehicle Images'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: _imageFileMap.keys.map((part) {
                return Column(
                  children: [
                    ListTile(
                      title: Text(part.replaceAll('_', ' ').toUpperCase()),
                      trailing: IconButton(
                        icon: Icon(Icons.upload),
                        onPressed: () => _pickImage(part),
                      ),
                    ),
                    if (_imageFileMap[part] != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.file(
                          File(_imageFileMap[part]!.path),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Divider(),
                  ],
                );
              }).toList(),
            ),
          ),
          ElevatedButton(
            onPressed: _generate3DModel,
            child: Text('Generate 3D Model'),
          ),
        ],
      ),
    );
  }
}

// ModelPage for after uploading all images
class ModelPage extends StatelessWidget {
  final Map<String, XFile?> imageFiles;

  ModelPage({required this.imageFiles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('3D Model'),
      ),
      body: Cube(
        onSceneCreated: (Scene scene) {
          scene.world.add(Object(
            fileName: 'assets/your_model_file.glb', // Update with your model file path
            position: Vector3(0.0, 0.0, 0.0),
            scale: Vector3(1.0, 1.0, 1.0),
          ));
        },
      ),
    );
  }
}





class _ScannerPageState extends State<ScannerPage> {
  bool mockMode = true;
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  String rpm = "0";
  List<Map<String, String>> faultCodes = [];
  bool isSearching = false;
  Timer? mockDTCTimer;
  String affectedPart = 'None';

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
    int numberOfCodes = random.nextInt(3) + 1; 
    String dtcResponse = "43";
    
    for (int i = 0; i < numberOfCodes; i++) {
      
      int codeNumber = random.nextInt(101) + 100; 
      String dtcCode = "P0" + codeNumber.toString();
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
      faultCodes = codes;
      affectedPart = getAffectedPart(codes);
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

  String getAffectedPart(List<Map<String, String>> codes) {
    if (codes.isEmpty) return 'None';

    String firstCode = codes[0]['code']!;
    switch (firstCode[0]) {
      case 'P':
        return 'Engine';
      case 'C':
        return 'Chassis';
      case 'B':
        return 'Body';
      case 'U':
        return 'Network';
      default:
        return 'Unknown';
    }
  }
  
@override
Widget build(BuildContext context) {
  return SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Add a new card for the mock mode toggle
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mode:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text(
                        mockMode ? 'Mock' : 'Actual',
                        style: TextStyle(fontSize: 16),
                      ),
                      Switch(
                        value: mockMode,
                        onChanged: (value) {
                          setState(() {
                            mockMode = value;
                            faultCodes.clear();
                            affectedPart = 'None';
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
                ],
              ),
            ),
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
            if (!mockMode)
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: ElevatedButton(
                onPressed: scanForDevices,
                child: Text('Scan for Devices'),
              ),
            ),
          SizedBox(height: 20),
          Text(
            '2D Car Indicator:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          CarIndicator(affectedPart: affectedPart),
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
          // Add a button for scanning devices when not in mock mode

        ],
      ),
    ),
  );
}

  @override
  void dispose() {
    stopMockDTCSimulation();
    super.dispose();
  }
}

class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: ClipOval(
                child: Image.asset(
                  'assets/vguard-logo.png',
                  width: 80,  // Adjust width to fit within the CircleAvatar
                  height: 80, // Adjust height to fit within the CircleAvatar
                  fit: BoxFit.cover,  // Ensure the logo covers the available space proportionally
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'About Vguard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'We are dedicated to providing accurate and reliable OBD-II diagnostics for your vehicle. Our app helps you understand your car\'s health and performance.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Version: 1.0.0',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}