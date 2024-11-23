import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crash Alert App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CrashAlertScreen(),
    );
  }
}

class CrashAlertScreen extends StatefulWidget {
  @override
  _CrashAlertScreenState createState() => _CrashAlertScreenState();
}

class _CrashAlertScreenState extends State<CrashAlertScreen> {
  String crashDetails = "No crash data received yet."; // Placeholder for details

  final List<Map<String, String>> emergencyContacts = [
    {"name": "Emergency Number", "number": "108"},
    {"name": "Contact 1", "number": "+911234567890"},
    {"name": "Contact 2", "number": "+919876543210"},
  ];

  void _callNumber(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      print("Cannot launch $number");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crash Alert')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crash Details Section
            Text(
              "Crash Details:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                crashDetails,
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 20),

            // Emergency Contacts Section
            Text(
              "Emergency Contacts:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: emergencyContacts.length,
                itemBuilder: (context, index) {
                  final contact = emergencyContacts[index];
                  return Card(
                    child: ListTile(
                      title: Text(contact["name"]!),
                      subtitle: Text(contact["number"]!),
                      trailing: IconButton(
                        icon: Icon(Icons.call),
                        onPressed: () => _callNumber(contact["number"]!),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
