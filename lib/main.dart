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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        '/about': (context) => const AboutScreen(),
        '/deliveryComplete': (context) => const DeliveryCompleteScreen(),
      },
    );
  }
}

// ─── Global session ──────────────────────────────────────────────────────────

class NavBotSession {
  static String userName = '';
  static String userEmail = '';
  static bool isLoggedIn = false;
}

// ─── Global data + delivery history ─────────────────────────────────────────

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

  static int totalDeliveries = 0;
  static int completedDeliveries = 0;

  static final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);
  static void Function()? _tickCallback;

  static void startGlobalSimulation() {
    if (isSimulationRunning) return;
    isSimulationRunning = true;
    robotStatus = 'Moving';
    activeStep = 'Leaving $pickupLocation';
    eta = '8 min';
    _runTick();
  }

  static void _runTick() {
    if (!isSimulationRunning) return;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!isSimulationRunning) return;
      progressValue = (progressValue + 0.008).clamp(0.0, 1.0);
      progressNotifier.value = progressValue;

      if (progressValue < 0.25) {
        currentLocation = 'Leaving $pickupLocation';
        activeStep = 'Leaving $pickupLocation';
        eta = '8 min';
      } else if (progressValue < 0.50) {
        currentLocation = 'In Corridor';
        activeStep = 'Navigating route';
        eta = '6 min';
      } else if (progressValue < 0.75) {
        currentLocation = 'Near destination';
        activeStep = 'Approaching destination';
        eta = '3 min';
      } else if (progressValue < 1.0) {
        currentLocation = 'At destination door';
        activeStep = 'Final approach';
        eta = '1 min';
      }

      if (progressValue >= 1.0) {
        robotStatus = 'Completed';
        deliveryCompleted = true;
        currentLocation = destinationLocation;
        activeStep = 'Delivery completed';
        eta = '0 min';
        isSimulationRunning = false;
        completedDeliveries += 1;
        progressNotifier.value = 1.0;
        _tickCallback?.call();
      } else {
        _runTick();
      }
    });
  }

  static void stopSimulation() {
    isSimulationRunning = false;
    robotStatus = 'Stopped';
    activeStep = 'Robot stopped manually';
  }

  static void resumeSimulation() {
    if (isSimulationRunning) return;
    isSimulationRunning = true;
    robotStatus = 'Moving';
    activeStep = 'Resuming route';
    _runTick();
  }

  static void reset() {
    robotStatus = 'Idle';
    currentLocation = 'Room A';
    destinationLocation = 'Room B';
    pickupLocation = 'Room A';
    packageDetails = '';
    progressValue = 0.0;
    requestSent = false;
    deliveryCompleted = false;
    eta = '-- min';
    activeStep = 'Waiting for request';
    isSimulationRunning = false;
    progressNotifier.value = 0.0;
  }
}

// ─── Shared AppBar ────────────────────────────────────────────────────────────

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
        child: Hero(
          tag: 'navbot_logo',
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
    ),
    title: Text(title,
        style: const TextStyle(
            color: Color(0xFF163A63), fontWeight: FontWeight.w800)),
    actions: actions,
  );
}

// ─── Status badge ─────────────────────────────────────────────────────────────

Widget _statusBadge(String status) {
  Color color;
  IconData icon;
  switch (status) {
    case 'Moving':
      color = Colors.green;
      icon = Icons.play_arrow_rounded;
      break;
    case 'Completed':
      color = Colors.blue;
      icon = Icons.check_circle_rounded;
      break;
    case 'Stopped':
      color = Colors.red;
      icon = Icons.stop_circle_rounded;
      break;
    default:
      color = Colors.orange;
      icon = Icons.hourglass_empty_rounded;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(status,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// LOGIN SCREEN
// ═════════════════════════════════════════════════════════════════════════════

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
  bool _obscurePassword = true;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
    _fade = Tween<double>(begin: 0, end: 1).animate(_controller);
    _scale = Tween<double>(begin: 0.85, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
        .map((e) =>
            e[0].toUpperCase() +
            (e.length > 1 ? e.substring(1).toLowerCase() : ''))
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
            colors: [Color(0xFFF8FBFF), Color(0xFFEAF4FF), Color(0xFFDCEEFF)],
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
                                        offset: Offset(0, 8))
                                  ],
                                ),
                                child: Hero(
                                  tag: 'navbot_logo',
                                  child: Image.asset(
                                    'navbot_app/assets/images/navbot_logo.png',
                                    height: 160,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text('NavBot',
                                  style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF163A63))),
                              const SizedBox(height: 6),
                              const Text('Smart Auto-Delivery System',
                                  style: TextStyle(
                                      fontSize: 15, color: Colors.black54)),
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
                                  offset: Offset(0, 5))
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
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Email required';
                                  if (!v.contains('@'))
                                    return 'Enter valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon:
                                      const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Password required';
                                  if (v.length < 4)
                                    return 'Minimum 4 characters';
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
                                  child: const Text('Signup')),
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

// ═════════════════════════════════════════════════════════════════════════════
// DASHBOARD SCREEN
// ═════════════════════════════════════════════════════════════════════════════

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
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _fade = Tween<double>(begin: 0, end: 1).animate(_controller);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    NavBotData.progressNotifier.addListener(_onProgress);
  }

  void _onProgress() {
    if (mounted) setState(() {});
    if (NavBotData.deliveryCompleted && mounted) {
      NavBotData.progressNotifier.removeListener(_onProgress);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted)
          Navigator.pushReplacementNamed(context, '/deliveryComplete');
      });
    }
  }

  @override
  void dispose() {
    NavBotData.progressNotifier.removeListener(_onProgress);
    _controller.dispose();
    super.dispose();
  }

  void _handleBottomNav(int index) {
    setState(() => _selectedIndex = index);
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
            colors: [Color(0xFF1F4E8C), Color(0xFF00BCD4)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Welcome, ${NavBotSession.userName}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900),
                ),
              ),
              _statusBadge(NavBotData.robotStatus),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your deliveries, create new requests, and track NavBot in real-time.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _quickStat(
                  Icons.smart_toy_rounded, 'Status', NavBotData.robotStatus),
              const SizedBox(width: 10),
              _quickStat(
                  Icons.place_rounded, 'Location', NavBotData.currentLocation),
              const SizedBox(width: 10),
              _quickStat(Icons.timer_outlined, 'ETA', NavBotData.eta),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickStat(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 10)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
    Widget? trailing,
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
                color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))
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
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _activeDeliveryBanner() {
    final pct = (NavBotData.progressValue * 100).toInt();
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/tracking'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy_rounded,
                      color: Colors.green, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delivery In Progress',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.green)),
                      Text(
                        '${NavBotData.currentLocation} → ${NavBotData.destinationLocation}  •  ETA ${NavBotData.eta}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
                Text('$pct%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.green,
                        fontSize: 16)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Colors.green),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: NavBotData.progressValue,
                minHeight: 8,
                backgroundColor: Colors.green.shade100,
                valueColor: const AlwaysStoppedAnimation(Colors.green),
              ),
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
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => const AboutScreen()),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/profile'),
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
                if (NavBotData.requestSent &&
                    !NavBotData.deliveryCompleted) ...[
                  _activeDeliveryBanner(),
                  const SizedBox(height: 14),
                ],
                _actionTile(
                  title: 'Create Delivery',
                  subtitle: 'Generate a new delivery request',
                  icon: Icons.add_box_rounded,
                  colors: const [Color(0xFF00BCD4), Color(0xFF36D1DC)],
                  onTap: () => Navigator.pushNamed(context, '/createDelivery'),
                ),
                const SizedBox(height: 14),
                _actionTile(
                  title: 'Track Robot',
                  subtitle: 'Watch live movement and progress',
                  icon: Icons.route_rounded,
                  colors: const [Color(0xFF1F4E8C), Color(0xFF355F9B)],
                  onTap: () => Navigator.pushNamed(context, '/tracking'),
                  trailing:
                      NavBotData.requestSent && !NavBotData.deliveryCompleted
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(NavBotData.progressValue * 100).toInt()}%',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800),
                              ),
                            )
                          : null,
                ),
                const SizedBox(height: 14),
                _actionTile(
                  title: 'Profile',
                  subtitle: 'View operator information',
                  icon: Icons.person_rounded,
                  colors: const [Color(0xFF7B61FF), Color(0xFF9A7BFF)],
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _handleBottomNav,
        selectedItemColor: const Color(0xFF1F4E8C),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline_rounded), label: 'Add'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CREATE DELIVERY SCREEN
// ═════════════════════════════════════════════════════════════════════════════

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
        vsync: this, duration: const Duration(milliseconds: 750))
      ..forward();
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
    NavBotData.progressValue = 0.0;
    NavBotData.progressNotifier.value = 0.0;
    NavBotData.totalDeliveries += 1;
    NavBotData.startGlobalSimulation();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Delivery request created!'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
    Navigator.pushNamed(context, '/tracking');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          buildNavBotAppBar(context, title: 'Create Delivery', showBack: true),
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
                        colors: [Color(0xFF1F4E8C), Color(0xFF00BCD4)]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.local_shipping_rounded,
                          color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Create New Delivery Request',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
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
                          offset: Offset(0, 5))
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
                          items: _destinations
                              .map((l) =>
                                  DropdownMenuItem(value: l, child: Text(l)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _destinationLocation = value!),
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
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Package details required';
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.warehouse_rounded,
                                  color: Color(0xFF1F4E8C), size: 18),
                              const SizedBox(width: 6),
                              Text(_pickupLocation,
                                  style: const TextStyle(
                                      color: Color(0xFF163A63),
                                      fontWeight: FontWeight.w700)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward_rounded,
                                    color: Color(0xFF1F4E8C), size: 18),
                              ),
                              const Icon(Icons.location_on_rounded,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 6),
                              Text(_destinationLocation,
                                  style: const TextStyle(
                                      color: Color(0xFF163A63),
                                      fontWeight: FontWeight.w700)),
                            ],
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

// ═════════════════════════════════════════════════════════════════════════════
// TRACKING SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    NavBotData.progressNotifier.addListener(_onProgress);
    NavBotData._tickCallback = () {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted)
            Navigator.pushReplacementNamed(context, '/deliveryComplete');
        });
      }
    };
  }

  void _onProgress() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    NavBotData.progressNotifier.removeListener(_onProgress);
    NavBotData._tickCallback = null;
    _pulseController.dispose();
    super.dispose();
  }

  Widget _trackingCard() {
    final progress = NavBotData.progressValue;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded, color: Color(0xFF1F4E8C)),
              const SizedBox(width: 8),
              const Text('Live Tracking',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF163A63))),
              const Spacer(),
              _statusBadge(NavBotData.robotStatus),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: LayoutBuilder(builder: (context, constraints) {
              final maxWidth = constraints.maxWidth - 85;
              final left = progress * maxWidth;
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
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 56,
                    child: Container(
                      width: maxWidth * progress,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF1F4E8C), Color(0xFF00BCD4)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    top: 28,
                    child: Column(children: [
                      Icon(Icons.warehouse_rounded, color: Color(0xFF1F4E8C)),
                      SizedBox(height: 4),
                      Text('Room A',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  Positioned(
                    left: left + 12,
                    top: 16,
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F4E8C).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.smart_toy_rounded,
                              color: Color(0xFF1F4E8C), size: 30),
                        ),
                        const SizedBox(height: 4),
                        const Text('NavBot',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 28,
                    child: Column(children: [
                      const Icon(Icons.location_on_rounded, color: Colors.red),
                      const SizedBox(height: 4),
                      Text(NavBotData.destinationLocation,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF1F4E8C)),
            ),
          ),
          const SizedBox(height: 8),
          Text('${(progress * 100).toInt()}%',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: Color(0xFF163A63))),
        ],
      ),
    );
  }

  Widget _infoCard(
      {required IconData icon,
      required String title,
      required String value,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.black54, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        color: Color(0xFF163A63), fontWeight: FontWeight.w800)),
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
      appBar: buildNavBotAppBar(context, title: 'Tracking', showBack: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _trackingCard(),
            const SizedBox(height: 14),
            _infoCard(
                icon: Icons.place_rounded,
                title: 'Current Location',
                value: NavBotData.currentLocation,
                color: const Color(0xFF00BCD4)),
            const SizedBox(height: 12),
            _infoCard(
                icon: Icons.smart_toy_rounded,
                title: 'Robot Status',
                value: NavBotData.robotStatus,
                color: const Color(0xFF1F4E8C)),
            const SizedBox(height: 12),
            _infoCard(
                icon: Icons.flag_rounded,
                title: 'Destination',
                value: NavBotData.destinationLocation,
                color: Colors.red),
            const SizedBox(height: 12),
            _infoCard(
                icon: Icons.timer_outlined,
                title: 'Estimated Time',
                value: NavBotData.eta,
                color: Colors.orange),
            const SizedBox(height: 12),
            _infoCard(
                icon: Icons.track_changes_rounded,
                title: 'Active Step',
                value: NavBotData.activeStep,
                color: Colors.green),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: NavBotData.stopSimulation,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Stop')),
                  ),
                ),
                if (canResume) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: NavBotData.resumeSimulation,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text('Resume')),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/dashboard'),
                    icon: const Icon(Icons.home_rounded),
                    label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Home')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DELIVERY COMPLETE SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class DeliveryCompleteScreen extends StatefulWidget {
  const DeliveryCompleteScreen({super.key});
  @override
  State<DeliveryCompleteScreen> createState() => _DeliveryCompleteScreenState();
}

class _DeliveryCompleteScreenState extends State<DeliveryCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0, end: 1).animate(_controller);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1F4E8C), Color(0xFF00BCD4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1F4E8C).withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 60),
                  ),
                ),
                const SizedBox(height: 32),
                SlideTransition(
                  position: _slide,
                  child: Column(
                    children: [
                      const Text('Delivery Complete!',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF163A63))),
                      const SizedBox(height: 10),
                      Text(
                        'Package successfully delivered to\n${NavBotData.destinationLocation}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black54, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 12,
                                offset: Offset(0, 5))
                          ],
                        ),
                        child: Column(
                          children: [
                            _summaryRow(
                                Icons.warehouse_rounded,
                                'Picked up from',
                                NavBotData.pickupLocation,
                                const Color(0xFF1F4E8C)),
                            const Divider(height: 24),
                            _summaryRow(
                                Icons.location_on_rounded,
                                'Delivered to',
                                NavBotData.destinationLocation,
                                Colors.red),
                            const Divider(height: 24),
                            _summaryRow(
                                Icons.inventory_2_rounded,
                                'Package',
                                NavBotData.packageDetails.isEmpty
                                    ? 'N/A'
                                    : NavBotData.packageDetails,
                                Colors.orange),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            NavBotData.reset();
                            Navigator.pushReplacementNamed(
                                context, '/dashboard');
                          },
                          icon: const Icon(Icons.home_rounded),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('Back to Dashboard',
                                style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            NavBotData.reset();
                            Navigator.pushReplacementNamed(
                                context, '/createDelivery');
                          },
                          icon: const Icon(Icons.add_box_rounded),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('New Delivery',
                                style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.black45, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF163A63),
                      fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PROFILE SCREEN
// ═════════════════════════════════════════════════════════════════════════════

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
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
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
                Text(title, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Color(0xFF163A63))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
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
      appBar: buildNavBotAppBar(context, title: 'Profile', showBack: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1F4E8C), Color(0xFF00BCD4)]),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    child: Text(_initials(userName),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF163A63))),
                  ),
                  const SizedBox(height: 12),
                  Text(userName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(userEmail,
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statChip(
                          '${NavBotData.totalDeliveries}', 'Total\nDeliveries'),
                      const SizedBox(width: 10),
                      _statChip(
                          '${NavBotData.completedDeliveries}', 'Completed'),
                      const SizedBox(width: 10),
                      _statChip(
                        NavBotData.totalDeliveries == 0
                            ? '0%'
                            : '${((NavBotData.completedDeliveries / NavBotData.totalDeliveries) * 100).toInt()}%',
                        'Success\nRate',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _profileTile(Icons.person_rounded, 'Name', userName),
            _profileTile(Icons.email_rounded, 'Email', userEmail),
            _profileTile(Icons.badge_outlined, 'Role', 'NavBot Operator'),
            _profileTile(Icons.smart_toy_rounded, 'Robot Status',
                NavBotData.robotStatus),
            _profileTile(Icons.verified_user_outlined, 'Status',
                NavBotSession.isLoggedIn ? 'Logged In' : 'Logged Out'),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  NavBotSession.userName = '';
                  NavBotSession.userEmail = '';
                  NavBotSession.isLoggedIn = false;
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Logout')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ABOUT SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('About NavBot',
            style: TextStyle(
                color: Color(0xFF163A63), fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Hero(
                tag: 'navbot_logo',
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 16,
                          offset: Offset(0, 8))
                    ],
                  ),
                  child: Image.asset(
                    'navbot_app/assets/images/navbot_logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('NavBot',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF163A63))),
            const SizedBox(height: 6),
            const Text('Smart Auto-Delivery Robot System',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54)),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Version 1.0.0',
                    style: TextStyle(
                        color: Color(0xFF1F4E8C), fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 28),
            _sectionTitle('About the Robot'),
            const SizedBox(height: 10),
            _infoCard(
              icon: Icons.smart_toy_rounded,
              title: 'What is NavBot?',
              value:
                  'NavBot is an autonomous indoor delivery robot designed to transport packages between rooms without human intervention. It uses smart navigation to plan routes and deliver items accurately.',
              color: const Color(0xFF1F4E8C),
            ),
            const SizedBox(height: 12),
            _infoCard(
              icon: Icons.route_rounded,
              title: 'How It Works',
              value:
                  'The operator creates a delivery request through the app, specifying pickup and drop-off locations. NavBot then navigates autonomously, sends live status updates, and confirms delivery on arrival.',
              color: const Color(0xFF00BCD4),
            ),
            const SizedBox(height: 12),
            _infoCard(
              icon: Icons.bolt_rounded,
              title: 'Key Features',
              value:
                  'Real-time tracking  •Autonomous path planning  •Live ETA updates  •Multi-room delivery  •Stop & Resume control  •Delivery history logging',
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            _sectionTitle('About the Project'),
            const SizedBox(height: 10),
            _infoCard(
              icon: Icons.account_balance_rounded,
              title: 'Institution',
              value:
                  'The Superior University, Lahore\nDepartment of Information Engineering Technology',
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 12),
            _infoCard(
              icon: Icons.group_rounded,
              title: 'Project Team — Group 3',
              // ← UPDATED with all 5 names
              value:
                  'Zainab  •Fizza  •Danish  •Hafiz Zain ul Abidin  •Hammad Awan',
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _infoCard(
              icon: Icons.phone_android_rounded,
              title: 'Platform',
              value: 'Built with Flutter — Cross-platform (Android & iOS)',
              color: Colors.teal,
            ),
            const SizedBox(height: 24),
            _sectionTitle('Contact Us'),
            const SizedBox(height: 10),
            _contactCard(Icons.email_rounded, 'Email',
                'su91-bietm-f23-028@superior.edu.pk', Colors.red),
            const SizedBox(height: 12),
            _contactCard(Icons.school_rounded, 'University',
                'Superior University', const Color(0xFF1F4E8C)),
            const SizedBox(height: 12),
            _contactCard(
                Icons.location_on_rounded,
                'Location',
                'FET Office, Superior University, Main Riwand Road, Lahore',
                Colors.orange),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Close')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF163A63)));
  }

  Widget _infoCard(
      {required IconData icon,
      required String title,
      required String value,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        color: Color(0xFF163A63),
                        fontWeight: FontWeight.w700,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.grey.shade300, size: 16),
        ],
      ),
    );
  }
}
