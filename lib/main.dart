import 'package:flutter/material.dart';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void main() {
  runApp(const NavBotApp());
}

class NavBotApp extends StatelessWidget {
  const NavBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NavBotSettings.darkMode,
      builder: (context, isDark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'NavBot',
          initialRoute: '/login',
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
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
                borderSide:
                    const BorderSide(color: Color(0xFF1F4E8C), width: 1.5),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1F4E8C),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
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
      },
    );
  }
}

// ─── Global session ──────────────────────────────────────────────────────────

class NavBotSession {
  static String userName = '';
  static String userEmail = '';
  static bool isLoggedIn = false;
  static final ValueNotifier<Uint8List?> profileImageBytes =
      ValueNotifier(null);
  static final ValueNotifier<String?> profileEmoji = ValueNotifier(null);
  static final ValueNotifier<Uint8List?> backgroundImageBytes =
      ValueNotifier(null);
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
    NavBotStore.addNotification(
      icon: Icons.smart_toy_rounded,
      color: const Color(0xFF1F4E8C),
      title: 'Delivery Started',
      subtitle:
          'NavBot is heading from $pickupLocation to $destinationLocation.',
    );
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
        NavBotStore.addNotification(
          icon: Icons.check_circle_rounded,
          color: Colors.green,
          title: 'Delivery Completed',
          subtitle: 'Package delivered to $destinationLocation successfully.',
        );
        NavBotStore.addHistory(DeliveryRecord(
          from: pickupLocation,
          to: destinationLocation,
          package: packageDetails.isEmpty ? 'No details' : packageDetails,
          status: 'Completed',
          time: DateTime.now(),
        ));
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
    NavBotStore.addNotification(
      icon: Icons.stop_circle_rounded,
      color: Colors.red,
      title: 'Delivery Stopped',
      subtitle: 'NavBot was manually stopped during delivery.',
    );
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

// ─── Global settings ──────────────────────────────────────────────────────────

class NavBotSettings {
  static final ValueNotifier<bool> darkMode = ValueNotifier(false);
  static final ValueNotifier<bool> notifications = ValueNotifier(true);
  static final ValueNotifier<bool> sound = ValueNotifier(true);
  static final ValueNotifier<bool> vibration = ValueNotifier(false);
  static final ValueNotifier<bool> autoTrack = ValueNotifier(true);
}

// ─── Delivery history entry ───────────────────────────────────────────────────

class DeliveryRecord {
  final String from;
  final String to;
  final String package;
  final String status;
  final DateTime time;
  DeliveryRecord({
    required this.from,
    required this.to,
    required this.package,
    required this.status,
    required this.time,
  });
}

// ─── Notification entry ───────────────────────────────────────────────────────

class NavNotification {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final DateTime time;
  NavNotification({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

// ─── Global history + notifications store ────────────────────────────────────

class NavBotStore {
  static final List<DeliveryRecord> history = [];
  static final ValueNotifier<List<NavNotification>> notifications =
      ValueNotifier([]);

  static void addNotification(
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle}) {
    notifications.value = [
      NavNotification(
          icon: icon,
          color: color,
          title: title,
          subtitle: subtitle,
          time: DateTime.now()),
      ...notifications.value,
    ];
  }

  static void addHistory(DeliveryRecord record) {
    history.insert(0, record);
  }
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
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4)),
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

// LAB 9: changed to TickerProviderStateMixin because TabController needs a second ticker
class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  // LAB 9: TabController added
  late TabController _tabController;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    // LAB 9: initialise TabController with 3 tabs
    _tabController = TabController(vsync: this, length: 3);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // optional: print('Tab changed: ${_tabController.index}');
      }
    });

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
    _tabController.dispose(); // LAB 9: dispose TabController
    _controller.dispose();
    super.dispose();
  }

  void _handleBottomNav(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/createDelivery');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  Widget _drawerTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? color : null,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
      ),
    );
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
          color: Colors.white.withValues(alpha: 0.14),
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
                color: Colors.white.withValues(alpha: 0.18),
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
                    color: Colors.green.withValues(alpha: 0.15),
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
      // ── LAB 9: Left Drawer — enhanced
      drawer: Drawer(
        child: Column(
          children: [
            ValueListenableBuilder<Uint8List?>(
              valueListenable: NavBotSession.backgroundImageBytes,
              builder: (context, bgBytes, _) {
                return UserAccountsDrawerHeader(
                  margin: EdgeInsets.zero,
                  currentAccountPicture: ValueListenableBuilder<Uint8List?>(
                    valueListenable: NavBotSession.profileImageBytes,
                    builder: (context, imgBytes, _) {
                      return ValueListenableBuilder<String?>(
                        valueListenable: NavBotSession.profileEmoji,
                        builder: (context, emoji, _) {
                          return CircleAvatar(
                            backgroundColor: Colors.white,
                            backgroundImage:
                                imgBytes != null ? MemoryImage(imgBytes) : null,
                            child: imgBytes == null
                                ? (emoji != null
                                    ? Text(emoji,
                                        style: const TextStyle(fontSize: 32))
                                    : Text(
                                        NavBotSession.userName.isEmpty
                                            ? 'N'
                                            : NavBotSession.userName[0]
                                                .toUpperCase(),
                                        style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF1F4E8C)),
                                      ))
                                : null,
                          );
                        },
                      );
                    },
                  ),
                  accountName: Row(
                    children: [
                      Text(
                        NavBotSession.userName.isEmpty
                            ? 'NavBot User'
                            : NavBotSession.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: NavBotData.robotStatus == 'Moving'
                              ? Colors.green
                              : NavBotData.robotStatus == 'Completed'
                                  ? Colors.blue
                                  : NavBotData.robotStatus == 'Stopped'
                                      ? Colors.red
                                      : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          NavBotData.robotStatus,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  accountEmail: Text(
                    NavBotSession.userEmail.isEmpty
                        ? 'user@navbot.com'
                        : NavBotSession.userEmail,
                  ),
                  decoration: BoxDecoration(
                    gradient: bgBytes == null
                        ? const LinearGradient(
                            colors: [Color(0xFF1F4E8C), Color(0xFF00BCD4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    image: bgBytes != null
                        ? DecorationImage(
                            image: MemoryImage(bgBytes),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.30),
                              BlendMode.darken,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
            if (NavBotData.requestSent && !NavBotData.deliveryCompleted)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.smart_toy_rounded,
                            color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        const Text('Delivery in progress',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                        const Spacer(),
                        Text(
                          '${(NavBotData.progressValue * 100).toInt()}%',
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w900,
                              fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: NavBotData.progressValue,
                        minHeight: 6,
                        backgroundColor: Colors.green.shade100,
                        valueColor: const AlwaysStoppedAnimation(Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 12),
                children: [
                  _drawerTile(
                    context,
                    icon: Icons.home_rounded,
                    color: const Color(0xFF1F4E8C),
                    title: 'Home',
                    active: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.history_rounded,
                    color: const Color(0xFF00BCD4),
                    title: 'History',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HistoryScreen()),
                      );
                    },
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.notifications_rounded,
                    color: Colors.orange,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificationsScreen()),
                      );
                    },
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.settings_rounded,
                    color: Colors.grey,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.info_outline_rounded,
                    color: Colors.deepPurple,
                    title: 'About',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/about');
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _drawerTile(
              context,
              icon: Icons.logout_rounded,
              color: Colors.red,
              title: 'Logout',
              onTap: () {
                NavBotSession.userName = '';
                NavBotSession.userEmail = '';
                NavBotSession.isLoggedIn = false;
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Text(
                'NavBot v1.0.0',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // LAB 9: Drawer menu icon on the left
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF163A63)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Dashboard',
            style: TextStyle(
                color: Color(0xFF163A63), fontWeight: FontWeight.w800)),
        // Logo on the right side
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/dashboard'),
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
                                color: Colors.white.withValues(alpha: 0.2),
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
      // ── LAB 9: TabBar added — kept alongside existing BottomNavigationBar
      // structure: TabBar sits on top of BottomNavigationBar inside a Column
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // LAB 9: TabBar with TabController
          SafeArea(
            bottom: false,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1F4E8C),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF1F4E8C),
              tabs: const [
                Tab(icon: Icon(Icons.home_rounded), text: 'Home'),
                Tab(icon: Icon(Icons.add_circle_outline_rounded), text: 'Add'),
                Tab(icon: Icon(Icons.person_rounded), text: 'Profile'),
              ],
              onTap: _handleBottomNav,
            ),
          ),
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
    NavBotStore.addNotification(
      icon: Icons.local_shipping_rounded,
      color: const Color(0xFF00BCD4),
      title: 'New Delivery Request',
      subtitle:
          'Delivery created from $_pickupLocation to $_destinationLocation.',
    );

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
                            color:
                                const Color(0xFF1F4E8C).withValues(alpha: 0.1),
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
                color: color.withValues(alpha: 0.12),
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
                          color: const Color(0xFF1F4E8C).withValues(alpha: 0.3),
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
              color: color.withValues(alpha: 0.1),
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── emoji list ────────────────────────────────────────────────────────────
  static const List<String> _emojis = [
    '😀',
    '😎',
    '🤖',
    '👨‍💻',
    '👩‍💻',
    '🧑‍🚀',
    '👷',
    '🦾',
    '🐱',
    '🐶',
    '🦊',
    '🐼',
    '🐸',
    '🦁',
    '🐯',
    '🐨',
    '🦄',
    '🐲',
    '🌟',
    '⚡',
    '🔥',
    '🌈',
    '💎',
    '🚀',
    '🛸',
    '🤩',
    '😇',
    '🥷',
    '🧠',
    '👑',
  ];

  String _initials(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'N';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // ── pick profile image from files ─────────────────────────────────────────
  Future<void> _pickProfileImage() async {
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();
    await input.onChange.first;
    if (input.files!.isEmpty) return;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(input.files![0]);
    await reader.onLoad.first;
    NavBotSession.profileImageBytes.value = reader.result as Uint8List;
    NavBotSession.profileEmoji.value = null;
  }

  // ── pick background image from files ─────────────────────────────────────
  Future<void> _pickBackgroundImage() async {
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();
    await input.onChange.first;
    if (input.files!.isEmpty) return;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(input.files![0]);
    await reader.onLoad.first;
    NavBotSession.backgroundImageBytes.value = reader.result as Uint8List;
  }

  // ── profile picture bottom sheet ──────────────────────────────────────────
  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        builder: (context, scrollController) => Column(
          children: [
            // handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Profile Picture',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            // action tiles
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F4E8C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: Color(0xFF1F4E8C)),
              ),
              title: const Text('Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Pick any image from your device'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage();
              },
            ),
            ValueListenableBuilder<Uint8List?>(
              valueListenable: NavBotSession.profileImageBytes,
              builder: (context, bytes, _) => bytes == null
                  ? const SizedBox.shrink()
                  : ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            const Icon(Icons.delete_rounded, color: Colors.red),
                      ),
                      title: const Text('Remove Photo',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: Colors.red)),
                      onTap: () {
                        Navigator.pop(context);
                        NavBotSession.profileImageBytes.value = null;
                      },
                    ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Or choose an emoji',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.black54)),
              ),
            ),
            // emoji grid
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _emojis.length,
                itemBuilder: (context, i) => ValueListenableBuilder<String?>(
                  valueListenable: NavBotSession.profileEmoji,
                  builder: (context, selected, _) => GestureDetector(
                    onTap: () {
                      NavBotSession.profileEmoji.value = _emojis[i];
                      NavBotSession.profileImageBytes.value = null;
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected == _emojis[i]
                            ? const Color(0xFF1F4E8C).withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: selected == _emojis[i]
                            ? Border.all(
                                color: const Color(0xFF1F4E8C), width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(_emojis[i],
                            style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── background picture bottom sheet ───────────────────────────────────────
  void _showBackgroundOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Profile Background',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.wallpaper_rounded,
                      color: Color(0xFF00BCD4)),
                ),
                title: const Text('Choose Background Image',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle:
                    const Text('Pick any image as your profile background'),
                onTap: () {
                  Navigator.pop(context);
                  _pickBackgroundImage();
                },
              ),
              ValueListenableBuilder<Uint8List?>(
                valueListenable: NavBotSession.backgroundImageBytes,
                builder: (context, bytes, _) => bytes == null
                    ? const SizedBox.shrink()
                    : ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_rounded,
                              color: Colors.red),
                        ),
                        title: const Text('Remove Background',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          NavBotSession.backgroundImageBytes.value = null;
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          color: Colors.white.withValues(alpha: 0.18),
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
            // ── Profile header card ─────────────────────────────────────────
            ValueListenableBuilder<Uint8List?>(
              valueListenable: NavBotSession.backgroundImageBytes,
              builder: (context, bgBytes, _) {
                return Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: bgBytes == null
                        ? const LinearGradient(
                            colors: [Color(0xFF1F4E8C), Color(0xFF00BCD4)])
                        : null,
                    image: bgBytes != null
                        ? DecorationImage(
                            image: MemoryImage(bgBytes),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.35),
                              BlendMode.darken,
                            ),
                          )
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            // Profile picture
                            GestureDetector(
                              onTap: _showProfileOptions,
                              child: Stack(
                                children: [
                                  ValueListenableBuilder<Uint8List?>(
                                    valueListenable:
                                        NavBotSession.profileImageBytes,
                                    builder: (context, imgBytes, _) {
                                      return ValueListenableBuilder<String?>(
                                        valueListenable:
                                            NavBotSession.profileEmoji,
                                        builder: (context, emoji, _) {
                                          return CircleAvatar(
                                            radius: 48,
                                            backgroundColor: Colors.white,
                                            backgroundImage: imgBytes != null
                                                ? MemoryImage(imgBytes)
                                                : null,
                                            child: imgBytes == null
                                                ? (emoji != null
                                                    ? Text(emoji,
                                                        style: const TextStyle(
                                                            fontSize: 40))
                                                    : Text(
                                                        _initials(userName),
                                                        style: const TextStyle(
                                                            fontSize: 28,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            color: Color(
                                                                0xFF163A63)),
                                                      ))
                                                : null,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00BCD4),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.edit_rounded,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                                ],
                              ),
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
                                _statChip('${NavBotData.totalDeliveries}',
                                    'Total\nDeliveries'),
                                const SizedBox(width: 10),
                                _statChip('${NavBotData.completedDeliveries}',
                                    'Completed'),
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
                      // ── Change background button (top right) ───────────────
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: _showBackgroundOptions,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.wallpaper_rounded,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Background',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
                  NavBotSession.profileImageBytes.value = null;
                  NavBotSession.profileEmoji.value = null;
                  NavBotSession.backgroundImageBytes.value = null;
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
// HISTORY SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${t.day}/${t.month}/${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    final history = NavBotStore.history;
    return Scaffold(
      appBar: buildNavBotAppBar(context, title: 'History', showBack: true),
      body: SafeArea(
        child: history.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded,
                        size: 64, color: Colors.black26),
                    SizedBox(height: 12),
                    Text('No delivery history yet',
                        style: TextStyle(color: Colors.black45, fontSize: 16)),
                    SizedBox(height: 6),
                    Text('Completed deliveries will\nappear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black38, fontSize: 13)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final r = history[index];
                  final isCompleted = r.status == 'Completed';
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.withValues(alpha: 0.12)
                                : Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: isCompleted ? Colors.green : Colors.orange,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(r.from,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: Color(0xFF163A63))),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 6),
                                    child: Icon(Icons.arrow_forward_rounded,
                                        size: 14, color: Colors.black38),
                                  ),
                                  Text(r.to,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: Color(0xFF163A63))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(r.package,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : Colors.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(r.status,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isCompleted
                                          ? Colors.green
                                          : Colors.orange)),
                            ),
                            const SizedBox(height: 4),
                            Text(_formatTime(r.time),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.black38)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day(s) ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildNavBotAppBar(
        context,
        title: 'Notifications',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear all',
            onPressed: () {
              NavBotStore.notifications.value = [];
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<NavNotification>>(
          valueListenable: NavBotStore.notifications,
          builder: (context, notifications, _) {
            if (notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_rounded,
                        size: 64, color: Colors.black26),
                    SizedBox(height: 12),
                    Text('No notifications yet',
                        style: TextStyle(color: Colors.black45, fontSize: 16)),
                    SizedBox(height: 6),
                    Text(
                        'Notifications will appear here when\ndeliveries are created or updated.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black38, fontSize: 13)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return Dismissible(
                  key: Key(n.time.toString() + index.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.delete_rounded, color: Colors.red),
                  ),
                  onDismissed: (_) {
                    final updated = List<NavNotification>.from(
                        NavBotStore.notifications.value)
                      ..removeAt(index);
                    NavBotStore.notifications.value = updated;
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: n.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(n.icon, color: n.color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Color(0xFF163A63))),
                              const SizedBox(height: 4),
                              Text(n.subtitle,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_timeAgo(n.time),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black38)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SETTINGS SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _settingsTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required ValueNotifier<bool> notifier,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, value, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black45)),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: (v) => notifier.value = v,
                activeColor: const Color(0xFF1F4E8C),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildNavBotAppBar(context, title: 'Settings', showBack: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text('Notifications',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black45)),
            ),
            _settingsTile(
              icon: Icons.notifications_rounded,
              color: Colors.orange,
              title: 'Push Notifications',
              subtitle: 'Receive delivery updates',
              notifier: NavBotSettings.notifications,
            ),
            _settingsTile(
              icon: Icons.volume_up_rounded,
              color: const Color(0xFF00BCD4),
              title: 'Sound',
              subtitle: 'Play sound on alerts',
              notifier: NavBotSettings.sound,
            ),
            _settingsTile(
              icon: Icons.vibration_rounded,
              color: const Color(0xFF7B61FF),
              title: 'Vibration',
              subtitle: 'Vibrate on alerts',
              notifier: NavBotSettings.vibration,
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text('App',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black45)),
            ),
            _settingsTile(
              icon: Icons.dark_mode_rounded,
              color: const Color(0xFF163A63),
              title: 'Dark Mode',
              subtitle: 'Switch to dark theme',
              notifier: NavBotSettings.darkMode,
            ),
            _settingsTile(
              icon: Icons.track_changes_rounded,
              color: Colors.green,
              title: 'Auto Track',
              subtitle: 'Auto open tracking on delivery start',
              notifier: NavBotSettings.autoTrack,
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
                color: color.withValues(alpha: 0.12),
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
                color: color.withValues(alpha: 0.12),
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
