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

  final TextEditingController destinationController = TextEditingController();

  void startDelivery() {
    setState(() {
      status = "Delivering";
      location = destinationController.text.isEmpty
          ? "Unknown"
          : destinationController.text;
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
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              // 🖼️ IMAGE (LAB 6)
              Container(
                margin: EdgeInsets.all(10),
                child: Image.network(
                  "https://cdn-icons-png.flaticon.com/512/4712/4712027.png",
                  height: 120,
                ),
              ),

              // CUSTOM CARD
              RobotCard(status: status, location: location),

              SizedBox(height: 10),

              // 🧾 FORM FIELD (LAB 6)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: destinationController,
                  decoration: InputDecoration(
                    labelText: "Enter Destination",
                    hintText: "e.g. Room 101",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // BUTTONS WITH ICONS (LAB 6)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: startDelivery,
                    icon: Icon(Icons.play_arrow),
                    label: Text("Start"),
                  ),
                  ElevatedButton.icon(
                    onPressed: stopDelivery,
                    icon: Icon(Icons.stop),
                    label: Text("Stop"),
                  ),
                ],
              ),

              SizedBox(height: 15),

              ElevatedButton.icon(
                onPressed: returnToBase,
                icon: Icon(Icons.home),
                label: Text("Return to Base"),
              ),
            ],
          ),
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
          // ICON (LAB 6)
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
