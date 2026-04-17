import 'package:flutter/material.dart';

void main() {
  runApp(const NavBotApp());
}

class NavBotApp extends StatelessWidget {
  const NavBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NavBot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F4E8C),
        ),
        useMaterial3: true,
      ),
      home: const NavBotHomePage(),
    );
  }
}

class NavBotHomePage extends StatefulWidget {
  const NavBotHomePage({super.key});

  @override
  State<NavBotHomePage> createState() => _NavBotHomePageState();
}

class _NavBotHomePageState extends State<NavBotHomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _packageIdController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<String> _rooms = ['Room B', 'Room C', 'Room D'];

  String? _selectedDestination;
  String _status = 'Idle';
  String _location = 'Room A (Warehouse)';
  String _destination = 'Not assigned';
  String _route = 'Room A → Not assigned';
  String _trackingStep = 'Waiting for assignment';
  IconData _statusIcon = Icons.pause_circle_outline;

  @override
  void dispose() {
    _packageIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _startDelivery() {
    if (!_formKey.currentState!.validate()) {
      _showMessage('Please complete the form first.');
      return;
    }

    setState(() {
      _destination = _selectedDestination!;
      _route = 'Room A → $_destination';
      _status = 'Delivering';
      _location = 'Moving from Room A to $_destination';
      _trackingStep = 'NavBot is on the way';
      _statusIcon = Icons.local_shipping_outlined;
    });

    _showMessage('Delivery started successfully.');
  }

  void _stopDelivery() {
    setState(() {
      _status = 'Stopped';
      _location = 'Paused between Room A and $_destination';
      _trackingStep = 'Delivery paused';
      _statusIcon = Icons.stop_circle_outlined;
    });

    _showMessage('NavBot delivery stopped.');
  }

  void _returnToBase() {
    setState(() {
      _status = 'Returning';
      _location = 'Returning to Room A (Warehouse)';
      _trackingStep = 'Returning to warehouse';
      _statusIcon = Icons.home_filled;
    });

    _showMessage('NavBot is returning to base.');
  }

  void _markDelivered() {
    if (_destination == 'Not assigned') {
      _showMessage('Please start a delivery first.');
      return;
    }

    setState(() {
      _status = 'Delivered';
      _location = _destination;
      _trackingStep = 'Package delivered successfully';
      _statusIcon = Icons.check_circle_outline;
    });

    _showMessage('Package delivered.');
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _packageIdController.clear();
    _notesController.clear();

    setState(() {
      _selectedDestination = null;
      _status = 'Idle';
      _location = 'Room A (Warehouse)';
      _destination = 'Not assigned';
      _route = 'Room A → Not assigned';
      _trackingStep = 'Waiting for assignment';
      _statusIcon = Icons.pause_circle_outline;
    });

    _showMessage('Form and robot status reset.');
  }

  String? _validateDropdown(String? value) {
    if (value == null || value.isEmpty) {
      return 'Destination is required';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Image.asset(
              'navbot_app/assets/images/navbot_logo.png',
              height: 140,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            const Text(
              'NavBot',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F4E8C),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Smart Auto-Delivery',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7EC8F8)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon, size: 34, color: const Color(0xFF1F4E8C)),
              const SizedBox(width: 10),
              const Text(
                'Robot Status',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(Icons.info_outline, 'Status', _status),
          _buildInfoRow(Icons.place_outlined, 'Current Location', _location),
          _buildInfoRow(Icons.flag_outlined, 'Destination', _destination),
          _buildInfoRow(Icons.alt_route_outlined, 'Route', _route),
        ],
      ),
    );
  }

  Widget _buildTrackingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.route, color: Color(0xFF1F4E8C)),
                SizedBox(width: 8),
                Text(
                  'Tracking',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildInfoRow(Icons.home_work_outlined, 'Warehouse', 'Room A'),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Available Destinations',
              'Room B, Room C, Room D',
            ),
            _buildInfoRow(Icons.navigation_outlined, 'Current Route', _route),
            _buildInfoRow(
                Icons.track_changes_outlined, 'Tracking Step', _trackingStep),
            const SizedBox(height: 10),
            const Text(
              'Route Options',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const ListTile(
              dense: true,
              leading: Icon(Icons.arrow_forward, color: Colors.blue),
              title: Text('Room A → Room B'),
            ),
            const ListTile(
              dense: true,
              leading: Icon(Icons.arrow_forward, color: Colors.blue),
              title: Text('Room A → Room C'),
            ),
            const ListTile(
              dense: true,
              leading: Icon(Icons.arrow_forward, color: Colors.blue),
              title: Text('Room A → Room D'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00BCD4)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.assignment_outlined, color: Color(0xFF1F4E8C)),
                  SizedBox(width: 8),
                  Text(
                    'Delivery Form',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDestination,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  hintText: 'Select destination room',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: _rooms.map((room) {
                  return DropdownMenuItem<String>(
                    value: room,
                    child: Text(room),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDestination = value;
                  });
                },
                validator: _validateDropdown,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _packageIdController,
                decoration: InputDecoration(
                  labelText: 'Package ID',
                  hintText: 'Enter package ID',
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) => _validateRequired(value, 'Package ID'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Add special delivery instructions',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 52),
                    child: Icon(Icons.note_alt_outlined),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isPortrait) {
    final buttons = [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _startDelivery,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start'),
        ),
      ),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _stopDelivery,
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
        ),
      ),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _returnToBase,
          icon: const Icon(Icons.home_work_outlined),
          label: const Text('Return'),
        ),
      ),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _markDelivered,
          icon: const Icon(Icons.check),
          label: const Text('Delivered'),
        ),
      ),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _resetForm,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
        ),
      ),
    ];

    if (isPortrait) {
      return Column(
        children: [
          Row(
            children: [buttons[0], const SizedBox(width: 10), buttons[1]],
          ),
          const SizedBox(height: 10),
          Row(
            children: [buttons[2], const SizedBox(width: 10), buttons[3]],
          ),
          const SizedBox(height: 10),
          Row(
            children: [buttons[4]],
          ),
        ],
      );
    }

    return Row(
      children: [
        buttons[0],
        const SizedBox(width: 10),
        buttons[1],
        const SizedBox(width: 10),
        buttons[2],
        const SizedBox(width: 10),
        buttons[3],
        const SizedBox(width: 10),
        buttons[4],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NavBot'),
        centerTitle: true,
        leading: const Icon(Icons.smart_toy_outlined),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.settings_suggest_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: isPortrait
              ? Column(
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 16),
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    _buildTrackingCard(),
                    const SizedBox(height: 16),
                    _buildFormCard(),
                    const SizedBox(height: 16),
                    _buildActionButtons(true),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildHeaderCard()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatusCard()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTrackingCard(),
                    const SizedBox(height: 16),
                    _buildFormCard(),
                    const SizedBox(height: 16),
                    _buildActionButtons(false),
                  ],
                ),
        ),
      ),
    );
  }
}