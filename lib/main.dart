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
      initialRoute: '/login',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F4E8C),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F9FF),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF1F4E8C), width: 1.5),
          ),
        ),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/createDelivery': (context) => const CreateDeliveryScreen(),
        '/tracking': (context) => const TrackingScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

class NavBotSession {
  static String userName = '';
  static String userEmail = '';
  static bool isLoggedIn = false;
}

class NavBotData {
  static String robotStatus = 'Idle';
  static String currentLocation = 'Room A';
  static String destinationLocation = 'Room B';
  static String pickupLocation = 'Room A';
  static String packageDetails = '';
  static double progressValue = 0.0;
  static bool requestSent = false;
  static bool deliveryCompleted = false;
  static String eta = '-- min';
  static String activeStep = 'Waiting for request';
  static bool isSimulationRunning = false;
}

PreferredSizeWidget buildNavBotAppBar(
  BuildContext context, {
  required String title,
  bool showBack = false,
  List<Widget>? actions,
}) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    leadingWidth: 64,
    leading: Padding(
      padding: const EdgeInsets.only(left: 12),
      child: GestureDetector(
        onTap: () {
          if (showBack) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        },
        child: Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            'navbot_app/assets/images/navbot_logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: Color(0xFF163A63),
        fontWeight: FontWeight.w800,
      ),
    ),
    actions: actions,
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fade = Tween<double>(begin: 0, end: 1).animate(_controller);
    _scale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _extractName(String email) {
    final base = email.split('@').first.trim();
    if (base.isEmpty) return 'NavBot User';
    final cleaned = base.replaceAll(RegExp(r'[._\-0-9]+'), ' ').trim();
    if (cleaned.isEmpty) return 'NavBot User';
    return cleaned
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map(
          (e) =>
              e[0].toUpperCase() +
              (e.length > 1 ? e.substring(1).toLowerCase() : ''),
        )
        .join(' ');
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    NavBotSession.userEmail = _emailController.text.trim();
    NavBotSession.userName = _extractName(_emailController.text.trim());
    NavBotSession.isLoggedIn = true;

    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8FBFF),
              Color(0xFFEAF4FF),
              Color(0xFFDCEEFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SlideTransition(
                  position: _slide,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: _scale,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 16,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'navbot_app/assets/images/navbot_logo.png',
                                  height: 160,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'NavBot',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF163A63),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Smart Auto-Delivery System',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 12,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon:
                                      Icon(Icons.alternate_email_rounded),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email required';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Enter valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline_rounded),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Password required';
                                  }
                                  if (value.length < 4) {
                                    return 'Minimum 4 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _login,
                                  icon: const Icon(Icons.login_rounded),
                                  label: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    child: Text('Login'),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text('Signup'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fade = Tween<double>(begin: 0, end: 1).animate(_controller);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBottomNav(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/createDelivery');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F4E8C), Color(0xFF00BCD4)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${NavBotSession.userName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your deliveries, create new requests, and track NavBot in a cleaner smart interface.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Robot Status: ${NavBotData.robotStatus}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildNavBotAppBar(
        context,
        title: 'Dashboard',
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _heroCard(),
                const SizedBox(height: 18),
                _actionTile(
                  title: 'Create Delivery',
                  subtitle: 'Generate a new delivery request',
                  icon: Icons.add_box_rounded,
                  colors: const [Color(0xFF00BCD4), Color(0xFF36D1DC)],
                  onTap: () {
                    Navigator.pushNamed(context, '/createDelivery');
                  },
                ),
                const SizedBox(height: 14),
                _actionTile(
                  title: 'Track Robot',
                  subtitle: 'Watch live movement and progress',
                  icon: Icons.route_rounded,
                  colors: const [Color(0xFF1F4E8C), Color(0xFF355F9B)],
                  onTap: () {
                    Navigator.pushNamed(context, '/tracking');
                  },
                ),
                const SizedBox(height: 14),
                _actionTile(
                  title: 'Profile',
                  subtitle: 'View operator information',
                  icon: Icons.person_rounded,
                  colors: const [Color(0xFF7B61FF), Color(0xFF9A7BFF)],
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _handleBottomNav,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.add_circle), label: 'Add'),
          NavigationDestination(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class CreateDeliveryScreen extends StatefulWidget {
  const CreateDeliveryScreen({super.key});

  @override
  State<CreateDeliveryScreen> createState() => _CreateDeliveryScreenState();
}

class _CreateDeliveryScreenState extends State<CreateDeliveryScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _packageController = TextEditingController();

  final List<String> _destinations = ['Room B', 'Room C', 'Room D'];

  String _pickupLocation = 'Room A';
  String _destinationLocation = 'Room B';

  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fade = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _packageController.dispose();
    super.dispose();
  }

  void _sendRequest() {
    if (!_formKey.currentState!.validate()) return;

    NavBotData.pickupLocation = _pickupLocation;
    NavBotData.destinationLocation = _destinationLocation;
    NavBotData.packageDetails = _packageController.text.trim();
    NavBotData.requestSent = true;
    NavBotData.deliveryCompleted = false;
    NavBotData.robotStatus = 'Ready to Move';
    NavBotData.currentLocation = _pickupLocation;
    NavBotData.progressValue = 0.0;
    NavBotData.activeStep = 'Request created';
    NavBotData.eta = '8 min';
    NavBotData.isSimulationRunning = false;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delivery request created successfully')),
    );

    Navigator.pushNamed(context, '/tracking');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildNavBotAppBar(
        context,
        title: 'Create Delivery',
        showBack: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1F4E8C), Color(0xFF00BCD4)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.local_shipping_rounded,
                          color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Create New Delivery Request',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: _pickupLocation,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Pickup Location',
                            prefixIcon: Icon(Icons.warehouse_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: _destinationLocation,
                          items: _destinations.map((location) {
                            return DropdownMenuItem(
                              value: location,
                              child: Text(location),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _destinationLocation = value!;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Destination Location',
                            prefixIcon: Icon(Icons.location_on_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _packageController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Package Details',
                            alignLabelWithHint: true,
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 54),
                              child: Icon(Icons.inventory_2_rounded),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Package details required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF4FF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            'Estimated Route: Room A → $_destinationLocation',
                            style: const TextStyle(
                              color: Color(0xFF163A63),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _sendRequest,
                            icon: const Icon(Icons.send_rounded),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Text('Send Request'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _robotAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _robotAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    if (NavBotData.requestSent && !NavBotData.deliveryCompleted) {
      _startSimulation();
    }
  }

  void _startSimulation() {
    if (NavBotData.isSimulationRunning) return;

    NavBotData.isSimulationRunning = true;
    NavBotData.robotStatus = 'Moving';
    NavBotData.activeStep = 'Leaving Room A';
    NavBotData.eta = '8 min';

    _progressController.addListener(() {
      final progress = _progressController.value;

      setState(() {
        NavBotData.progressValue = progress;

        if (progress < 0.25) {
          NavBotData.currentLocation = 'Leaving Room A';
          NavBotData.activeStep = 'Leaving Room A';
          NavBotData.eta = '8 min';
        } else if (progress < 0.50) {
          NavBotData.currentLocation = 'In Corridor';
          NavBotData.activeStep = 'Navigating route';
          NavBotData.eta = '6 min';
        } else if (progress < 0.75) {
          NavBotData.currentLocation = 'Near destination area';
          NavBotData.activeStep = 'Approaching destination';
          NavBotData.eta = '3 min';
        } else if (progress < 1.0) {
          NavBotData.currentLocation = 'At destination door';
          NavBotData.activeStep = 'Final approach';
          NavBotData.eta = '1 min';
        } else {
          NavBotData.currentLocation = NavBotData.destinationLocation;
        }
      });
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          NavBotData.robotStatus = 'Completed';
          NavBotData.deliveryCompleted = true;
          NavBotData.currentLocation = NavBotData.destinationLocation;
          NavBotData.progressValue = 1.0;
          NavBotData.activeStep = 'Delivery completed';
          NavBotData.eta = '0 min';
          NavBotData.isSimulationRunning = false;
        });
      }
    });

    _progressController.forward(from: NavBotData.progressValue);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _stopRobot() {
    _progressController.stop();
    setState(() {
      NavBotData.robotStatus = 'Stopped';
      NavBotData.activeStep = 'Robot stopped manually';
      NavBotData.isSimulationRunning = false;
    });
  }

  void _resumeRobot() {
    setState(() {
      NavBotData.robotStatus = 'Moving';
      NavBotData.activeStep = 'Resuming route';
      NavBotData.isSimulationRunning = true;
    });
    _progressController.forward();
  }

  Widget _trackingHero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.route_rounded, color: Color(0xFF1F4E8C)),
              SizedBox(width: 8),
              Text(
                'Live Tracking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF163A63),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth - 85;
                final left = _robotAnimation.value * maxWidth;

                return Stack(
                  children: [
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 56,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 56,
                      child: Container(
                        width: maxWidth * NavBotData.progressValue,
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1F4E8C), Color(0xFF00BCD4)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      top: 28,
                      child: Column(
                        children: [
                          Icon(Icons.warehouse_rounded,
                              color: Color(0xFF1F4E8C)),
                          SizedBox(height: 4),
                          Text(
                            'Room A',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: left + 12,
                      top: 16,
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F4E8C).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.smart_toy_rounded,
                                color: Color(0xFF1F4E8C),
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'NavBot',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 28,
                      child: Column(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: Colors.red),
                          const SizedBox(height: 4),
                          Text(
                            NavBotData.destinationLocation,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: NavBotData.progressValue,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF1F4E8C)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(NavBotData.progressValue * 100).toInt()}%',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF163A63),
            ),
          ),
        ],
      ),
    );
  }

  Widget _softInfo({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF163A63),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canResume =
        NavBotData.robotStatus == 'Stopped' && !NavBotData.deliveryCompleted;

    return Scaffold(
      appBar: buildNavBotAppBar(
        context,
        title: 'Tracking',
        showBack: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _trackingHero(),
            const SizedBox(height: 14),
            _softInfo(
              icon: Icons.place_rounded,
              title: 'Current Location',
              value: NavBotData.currentLocation,
              color: const Color(0xFF00BCD4),
            ),
            const SizedBox(height: 12),
            _softInfo(
              icon: Icons.smart_toy_rounded,
              title: 'Robot Status',
              value: NavBotData.robotStatus,
              color: const Color(0xFF1F4E8C),
            ),
            const SizedBox(height: 12),
            _softInfo(
              icon: Icons.flag_rounded,
              title: 'Destination',
              value: NavBotData.destinationLocation,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            _softInfo(
              icon: Icons.timer_outlined,
              title: 'Estimated Time',
              value: NavBotData.eta,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _softInfo(
              icon: Icons.track_changes_rounded,
              title: 'Active Step',
              value: NavBotData.activeStep,
              color: Colors.green,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _stopRobot,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Stop'),
                    ),
                  ),
                ),
                if (canResume) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resumeRobot,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Resume'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _initials(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'N';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _profileTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1F4E8C)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF163A63),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        NavBotSession.userName.isEmpty ? 'NavBot User' : NavBotSession.userName;
    final userEmail = NavBotSession.userEmail.isEmpty
        ? 'No email available'
        : NavBotSession.userEmail;

    return Scaffold(
      appBar: buildNavBotAppBar(
        context,
        title: 'Profile',
        showBack: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1F4E8C), Color(0xFF00BCD4)],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    child: Text(
                      _initials(userName),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF163A63),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _profileTile(Icons.person_rounded, 'Name', userName),
            _profileTile(Icons.email_rounded, 'Email', userEmail),
            _profileTile(Icons.badge_outlined, 'Role', 'NavBot Operator'),
            _profileTile(
              Icons.verified_user_outlined,
              'Status',
              NavBotSession.isLoggedIn ? 'Logged In' : 'Logged Out',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  NavBotSession.userName = '';
                  NavBotSession.userEmail = '';
                  NavBotSession.isLoggedIn = false;

                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Logout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}