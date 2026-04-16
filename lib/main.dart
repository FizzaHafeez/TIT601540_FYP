import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

// ROOT APP
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Delivery Robot',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

// HOME SCREEN
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String status = "Idle";
  String location = "Warehouse";

  void startDelivery() {
    setState(() {
      status = "Delivering";
      location = "On the Way";
    });
  }

  void stopDelivery() {
    setState(() {
      status = "Stopped";
    });
  }

  void returnToBase() {
    setState(() {
      status = "Returning";
      location = "Warehouse";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Smart Delivery Robot"),
        centerTitle: true,
        leading: Icon(Icons.menu),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              print("Notifications clicked");
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              print("Settings clicked");
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RobotCard(status: status, location: location),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: startDelivery,
                  child: Text("Start"),
                ),
                ElevatedButton(
                  onPressed: stopDelivery,
                  child: Text("Stop"),
                ),
              ],
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: returnToBase,
              child: Text("Return to Base"),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= CUSTOM WIDGET =================

class RobotCard extends StatelessWidget {
  final String status;
  final String location;

  RobotCard({required this.status, required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        children: [
          Icon(Icons.android, size: 60, color: Colors.blue),
          SizedBox(height: 10),
          Text(
            "Status: $status",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "Location: $location",
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
