import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

// Firebase configuration
final FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyAUSju9njfcVInJy_QHICNFmu87DvB-fuw',
  appId: '1:1056190182504:android:2cf36bfd0b473f7465b7dd',
  messagingSenderId: '1056190182504',
  projectId: 'iot-crashtime',
  storageBucket: 'iot-crashtime.firebasestorage.app',
);

// Initialize FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: firebaseOptions);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);

  // Initialize FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crash Alert App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'Roboto',
      ),
      home: CrashAlertScreen(),
    );
  }
}

class CrashAlertScreen extends StatefulWidget {
  @override
  _CrashAlertScreenState createState() => _CrashAlertScreenState();
}

class _CrashAlertScreenState extends State<CrashAlertScreen> with SingleTickerProviderStateMixin {
  bool isCrashDetected = false;
  late AnimationController _animationController;
  String crashDetails = "No details";
  MaterialColor currentTheme = Colors.green;
  AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlayingSound = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: true);

    _setupFirebaseMessaging();
  }

  Future<void> _setupFirebaseMessaging() async {
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await FirebaseMessaging.instance.subscribeToTopic('All');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');
  }

  void _handleMessage(RemoteMessage message) {
    // Trigger vibration and sound
    _startAlertEffects();

    // Update UI
    setState(() {
      isCrashDetected = true;
      currentTheme = Colors.red;
      if (message.data.containsKey('details')) {
        crashDetails = message.data['details'];
      }
    });
  }

  Future<void> _startAlertEffects() async {
    // Vibrate device (requires flutter_vibrate package)
    if (await Vibrate.canVibrate) {
      Vibrate.vibrateWithPauses([
        Duration(milliseconds: 500),
        Duration(milliseconds: 300),
      ]);
    }

    if (!isPlayingSound) {
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('assets/sound/alert.mp3')); // Add an alert.mp3 sound file
      isPlayingSound = true;
    }
  }

  Future<void> _stopAlertEffects() async {
    // Stop vibration (no direct API; vibration stops when alert ends)
    // Stop sound
    await _audioPlayer.stop();
    isPlayingSound = false;

    // Reset crash detection
    setState(() {
      isCrashDetected = false;
      currentTheme = Colors.green;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
  final List<Map<String, dynamic>> emergencyContacts = [
    {
      "name": "Emergency Services",
      "number": "108",
      "type": "Ambulance"
    },
    {
      "name": "Police Control Room",
      "number": "100",
      "type": "Police"
    },
    {
      "name": "John Doe (Emergency Contact)",
      "number": "1234567890",
      "type": "Family"
    },
    {
      "name": "City Hospital",
      "number": "9876543210",
      "type": "Hospital"
    },
  ];

  void _callNumber(String number) async {
    String formattedNumber = number.replaceAll(RegExp(r'\s+'), '');
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: formattedNumber,
    );

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Call Error'),
                content: Text(
                    'Unable to make call to $number. Please try again.'),
                actions: <Widget>[
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: currentTheme,
                    ),
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Call Error'),
              content: Text('Error making call: $e'),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: currentTheme,
                  ),
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crash Alert', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: currentTheme[700],
        elevation: 0,
        actions: [
          if (isCrashDetected)
            IconButton(
              icon: Icon(Icons.stop),
              onPressed: _stopAlertEffects,
            )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [currentTheme[700]!, Colors.grey[50]!],
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              if (isCrashDetected)
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      width: double.infinity,
                      margin: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [currentTheme[700]!, currentTheme[900]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: currentTheme.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: _animationController.value * 5,
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      child: Column(
                        children: [
                          Icon(Icons.warning_rounded,
                              color: Colors.white.withOpacity(0.9),
                              size: 70),
                          SizedBox(height: 16),
                          Text(
                            'CRASH DETECTED!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please take some action',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // Map Section
              Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map,
                                  size: 56,
                                  color: Colors.grey[600]),
                              SizedBox(height: 12),
                              Text(
                                'Location Map',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 16,
                          top: 16,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: Colors.red[700],
                                    size: 16),
                                SizedBox(width: 4),
                                Text('Live Location',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w500,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Crash Details Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.red[700],
                              size: 24),
                          SizedBox(width: 12),
                          Text(
                            "Incident Details",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        crashDetails,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Emergency Contacts Section
              Container(
                margin: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 16),
                      child: Row(
                        children: [
                          Icon(Icons.contact_phone,
                              color: Colors.red[700],
                              size: 24),
                          SizedBox(width: 12),
                          Text(
                            "Emergency Contacts",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...emergencyContacts.map((contact) => Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            contact["type"] == "Police" ? Icons.local_police :
                            contact["type"] == "Hospital" ? Icons.local_hospital :
                            contact["type"] == "Ambulance" ? Icons.emergency :
                            Icons.person,
                            color: Colors.red[700],
                            size: 24,
                          ),
                        ),
                        title: Text(
                          contact["name"]!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        subtitle: Text(
                          contact["number"]!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: ElevatedButton.icon(
                          icon: Icon(Icons.call, size: 20),
                          label: Text("Call",
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          onPressed: () => _callNumber(contact["number"]!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}