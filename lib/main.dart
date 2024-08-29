import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Damage App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(cameras: cameras),
    );
  }
}

class MainPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MainPage({Key? key, required this.cameras}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomePage(cameras: widget.cameras),
      ScannerPage(cameras: widget.cameras),
      AboutPage(),
      SettingsPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'About',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomePage({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to Vguard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Scan your car for damage assessment',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              child: Text('Start Scanning'),
              onPressed: () {
                // Navigate to the scanner page
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ScannerPage(cameras: cameras),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ScannerPage({Key? key, required this.cameras}) : super(key: key);

  @override
  _ScannerPageState createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.cameras[0], ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
    loadModel();
  }

  Future loadModel() async {
    await Tflite.loadModel(
      model: "assets/car_damage_model.tflite",
      labels: "assets/car_damage_labels.txt",
    );
  }

  Future<void> detectDamage(CameraImage img) async {
    var recognitions = await Tflite.runModelOnFrame(
      bytesList: img.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      imageHeight: img.height,
      imageWidth: img.width,
      imageMean: 127.5,
      imageStd: 127.5,
      rotation: 90,
      numResults: 1,
      threshold: 0.1,
      asynch: true,
    );

    // Handle the recognitions...
    print(recognitions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Damage Scanner')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera),
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();
            // Process the image...
          } catch (e) {
            print(e);
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    Tflite.close();
    super.dispose();
  }
}
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = false;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      _selectedLanguage = prefs.getString('selected_language') ?? 'English';
    });
  }

  _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setString('selected_language', _selectedLanguage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _saveSettings();
            },
          ),
          ListTile(
            title: Text('Language'),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLanguage = newValue;
                  });
                  _saveSettings();
                }
              },
              items: <String>['English', 'Spanish', 'French', 'German']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          ListTile(
            title: Text('App Version'),
            trailing: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}
class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('About Us')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Car Damage Scanner App',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 20),
            Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 20),
            Text(
              'The Car Damage Scanner App is designed to help users quickly assess and document car damage using advanced image recognition technology.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 20),
            Text(
              'Key Features:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeatureItem('Real-time damage detection'),
                _buildFeatureItem('Easy-to-use interface'),
                _buildFeatureItem('Detailed damage reports'),
                _buildFeatureItem('Secure data storage'),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Contact Us:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 10),
            Text(
              'Email: support@cardamagescanner.com\nPhone: (123) 456-7890',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check, size: 20),
          SizedBox(width: 8),
          Text(feature),
        ],
      ),
    );
  }
}