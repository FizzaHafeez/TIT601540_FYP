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
            '/signup': (context) => const SignupScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/createDelivery': (context) => const CreateDeliveryScreen(),
            '/tracking': (context) => const TrackingScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/about': (context) => const AboutScreen(),
            '/deliveryComplete': (context) => const DeliveryCompleteScreen(),
            '/statsGrid': (context) => const StatsGridScreen(),
            '/robotFeatures': (context) => const RobotFeaturesScreen(),
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

  // FIX: Use a public ValueNotifier so all screens can safely listen
  static final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);

  // FIX: Use a public completion notifier instead of a private callback
  // to avoid double-navigation and tight coupling between screens.
  static final ValueNotifier<bool> completionNotifier = ValueNotifier(false);

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
        // FIX: Notify via ValueNotifier instead of a private callback,
        // so only the currently active screen handles navigation once.
        completionNotifier.value = true;
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
    // FIX: Reset completionNotifier so the next delivery can fire it again.
    completionNotifier.value = false;
    // NOTE: totalDeliveries and completedDeliveries are intentionally
    // NOT reset here — they are session-level counters, not per-delivery.
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

// ─── In-memory account store ──────────────────────────────────────────────────
// Stores registered accounts as email → {password, fullName} so signup/login
// works across screens within the same app session.

class NavBotAccounts {
  static final Map<String, Map<String, String>> _accounts = {};

  static bool register(String email, String password, String fullName) {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) return false; // already exists
    _accounts[key] = {'password': password, 'fullName': fullName};
    return true;
  }

  static Map<String, String>? login(String email, String password) {
    final key = email.trim().toLowerCase();
    final account = _accounts[key];
    if (account == null) return null;
    if (account['password'] != password) return null;
    return account;
  }

  static bool exists(String email) =>
      _accounts.containsKey(email.trim().toLowerCase());
}

// ═════════════════════════════════════════════════════════════════════════════
// SIGNUP SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _signup() {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = _nameController.text.trim();

    final registered = NavBotAccounts.register(email, password, fullName);
    if (!registered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.error_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('An account with this email already exists.'),
          ]),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white),
          SizedBox(width: 10),
          Expanded(child: Text('Account created! Please log in.')),
        ]),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
    // Go back to login, pre-filling the email
    Navigator.pop(context, email);
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
                        // ── Header ──────────────────────────────────────────
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1F4E8C), Color(0xFF00BCD4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 16,
                                  offset: Offset(0, 8))
                            ],
                          ),
                          child: const Icon(Icons.person_add_rounded,
                              color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 16),
                        const Text('Create Account',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF163A63))),
                        const SizedBox(height: 6),
                        const Text('Join NavBot to manage deliveries',
                            style:
                                TextStyle(fontSize: 14, color: Colors.black54)),
                        const SizedBox(height: 28),

                        // ── Form card ────────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(20),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Full name
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.badge_rounded),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Full name required';
                                  if (v.trim().length < 2)
                                    return 'Name too short';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon:
                                      Icon(Icons.alternate_email_rounded),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Email required';
                                  if (!v.contains('@') || !v.contains('.'))
                                    return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Password
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
                                  if (v == null || v.isEmpty)
                                    return 'Password required';
                                  if (v.length < 6)
                                    return 'Minimum 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Confirm password
                              TextFormField(
                                controller: _confirmController,
                                obscureText: _obscureConfirm,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: const Icon(Icons.lock_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConfirm
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded),
                                    onPressed: () => setState(() =>
                                        _obscureConfirm = !_obscureConfirm),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Please confirm your password';
                                  if (v != _passwordController.text)
                                    return 'Passwords do not match';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),

                              // Password hint
                              Row(
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      size: 13, color: Colors.grey.shade400),
                                  const SizedBox(width: 5),
                                  Text('Minimum 6 characters',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade400)),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Sign Up button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _signup,
                                  icon: const Icon(Icons.person_add_rounded),
                                  label: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    child: Text('Create Account',
                                        style: TextStyle(fontSize: 16)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Already have account ─────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account?',
                                style: TextStyle(color: Colors.black54)),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Log In',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1F4E8C))),
                            ),
                          ],
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
  String? _errorMessage;

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

  void _login() {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // No account registered with this email at all
    if (!NavBotAccounts.exists(email)) {
      setState(() => _errorMessage =
          'No account found for this email. Please sign up first.');
      return;
    }

    // Account exists — check password
    final account = NavBotAccounts.login(email, password);
    if (account == null) {
      setState(() => _errorMessage = 'Incorrect password. Please try again.');
      return;
    }

    // Credentials match — start session
    NavBotSession.userEmail = email;
    NavBotSession.userName = account['fullName']!;
    NavBotSession.isLoggedIn = true;
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  Future<void> _goToSignup() async {
    // SignupScreen returns the registered email so we can pre-fill it
    final registeredEmail = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
    if (registeredEmail != null && mounted) {
      _emailController.text = registeredEmail;
    }
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
                        // ── Logo + title ─────────────────────────────────────
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
                                    height: 120,
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

                        // ── Form card ─────────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(20),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Welcome back',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF163A63))),
                              const SizedBox(height: 4),
                              const Text('Sign in to your account',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black45)),
                              const SizedBox(height: 18),

                              // Error banner
                              if (_errorMessage != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline_rounded,
                                          color: Colors.red.shade600, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(_errorMessage!,
                                            style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ),

                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
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
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _login,
                                  icon: const Icon(Icons.login_rounded),
                                  label: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    child: Text('Login',
                                        style: TextStyle(fontSize: 16)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Divider ───────────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                                child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('OR',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                            Expanded(
                                child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Sign up card ──────────────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: const Color(0xFF1F4E8C)
                                    .withValues(alpha: 0.25)),
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
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF4FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.person_add_rounded,
                                    color: Color(0xFF1F4E8C), size: 22),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Don't have an account?",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF163A63))),
                                    SizedBox(height: 2),
                                    Text('Create one — it takes 30 seconds',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black45)),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _goToSignup,
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFF1F4E8C),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                ),
                                child: const Text('Sign Up',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
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
    with TickerProviderStateMixin {
  late TabController _tabController;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3);

    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _fade = Tween<double>(begin: 0, end: 1).animate(_controller);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    NavBotData.progressNotifier.addListener(_onProgress);
    // FIX: Dashboard only rebuilds UI on progress; it does NOT navigate to
    // deliveryComplete. Navigation is handled solely by TrackingScreen,
    // which is the active screen during a delivery. This prevents the
    // double-navigation crash that occurred when both screens listened and
    // both tried to push '/deliveryComplete' simultaneously.
  }

  void _onProgress() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    NavBotData.progressNotifier.removeListener(_onProgress);
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // FIX: Removed the empty indexIsChanging block. _handleBottomNav now
  // exclusively drives navigation so there is no conflict with TabController.
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
                    icon: Icons.bar_chart_rounded,
                    color: Colors.teal,
                    title: 'Stats & Overview',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/statsGrid');
                    },
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.precision_manufacturing_rounded,
                    color: const Color(0xFF00BCD4),
                    title: 'Robot Capabilities',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/robotFeatures');
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF163A63)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Dashboard',
            style: TextStyle(
                color: Color(0xFF163A63), fontWeight: FontWeight.w800)),
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
                const SizedBox(height: 14),
                _actionTile(
                  title: 'Stats & Overview',
                  subtitle: 'Cards & grid view of delivery stats',
                  icon: Icons.bar_chart_rounded,
                  colors: const [Color(0xFF009688), Color(0xFF4CAF50)],
                  onTap: () => Navigator.pushNamed(context, '/statsGrid'),
                ),
                const SizedBox(height: 14),
                _actionTile(
                  title: 'Robot Capabilities',
                  subtitle: 'Sliver-based features & specs view',
                  icon: Icons.precision_manufacturing_rounded,
                  colors: const [Color(0xFF0288D1), Color(0xFF00BCD4)],
                  onTap: () => Navigator.pushNamed(context, '/robotFeatures'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
    // FIX: Reset completionNotifier before starting so the TrackingScreen
    // listener fires fresh for this new delivery.
    NavBotData.completionNotifier.value = false;
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

  // FIX: Guard flag ensures navigation to /deliveryComplete fires exactly once
  // per delivery, even if the listener fires multiple times.
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    NavBotData.progressNotifier.addListener(_onProgress);

    // FIX: Listen to the public completionNotifier instead of using a private
    // _tickCallback. This eliminates the tight coupling and ensures only
    // TrackingScreen (the active screen) drives the final navigation.
    NavBotData.completionNotifier.addListener(_onCompletion);
  }

  void _onProgress() {
    if (mounted) setState(() {});
  }

  void _onCompletion() {
    if (!NavBotData.completionNotifier.value) return;
    if (_hasNavigated) return;
    _hasNavigated = true;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/deliveryComplete');
      }
    });
  }

  @override
  void dispose() {
    NavBotData.progressNotifier.removeListener(_onProgress);
    NavBotData.completionNotifier.removeListener(_onCompletion);
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
                    // FIX: Wrap static method calls in closures so Flutter's
                    // button system receives a proper VoidCallback.
                    onPressed: () => NavBotData.stopSimulation(),
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
                      // FIX: Same closure fix for resumeSimulation.
                      onPressed: () => NavBotData.resumeSimulation(),
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

// ═════════════════════════════════════════════════════════════════════════════
// NOTIFICATIONS SCREEN
// ═════════════════════════════════════════════════════════════════════════════

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
                  'Real-time tracking  •  Autonomous path planning  •  Live ETA updates  •  Multi-room delivery  •  Stop & Resume control  •  Delivery history logging',
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
                  'Zainab  •  Fizza  •  Danish  •  Hafiz Zain ul Abidin  •  Hammad Awan',
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

// ═════════════════════════════════════════════════════════════════════════════
// LAB 10 — STATS GRID SCREEN
// FIX: Converted to StatefulWidget so delivery stats refresh when the
// screen is opened after a delivery completes. StatelessWidget was caching
// stale values from NavBotData at build time with no way to rebuild.
// ═════════════════════════════════════════════════════════════════════════════

class StatsGridScreen extends StatefulWidget {
  const StatsGridScreen({super.key});
  @override
  State<StatsGridScreen> createState() => _StatsGridScreenState();
}

class _StatsGridScreenState extends State<StatsGridScreen> {
  @override
  void initState() {
    super.initState();
    // FIX: Listen to progressNotifier so the grid updates live during delivery.
    NavBotData.progressNotifier.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    NavBotData.progressNotifier.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Stat card data is now read fresh on every build, reflecting live values.
    final List<Map<String, dynamic>> statCards = [
      {
        'icon': Icons.local_shipping_rounded,
        'label': 'Total Deliveries',
        'value': '${NavBotData.totalDeliveries}',
        'color': const Color(0xFF1F4E8C),
        'bg': const Color(0xFFEAF4FF),
      },
      {
        'icon': Icons.check_circle_rounded,
        'label': 'Completed',
        'value': '${NavBotData.completedDeliveries}',
        'color': Colors.green,
        'bg': const Color(0xFFE8F5E9),
      },
      {
        'icon': Icons.percent_rounded,
        'label': 'Success Rate',
        'value': NavBotData.totalDeliveries == 0
            ? '0%'
            : '${((NavBotData.completedDeliveries / NavBotData.totalDeliveries) * 100).toInt()}%',
        'color': Colors.orange,
        'bg': const Color(0xFFFFF3E0),
      },
      {
        'icon': Icons.smart_toy_rounded,
        'label': 'Robot Status',
        'value': NavBotData.robotStatus,
        'color': const Color(0xFF00BCD4),
        'bg': const Color(0xFFE0F7FA),
      },
      {
        'icon': Icons.place_rounded,
        'label': 'Current Location',
        'value': NavBotData.currentLocation,
        'color': Colors.deepPurple,
        'bg': const Color(0xFFEDE7F6),
      },
      {
        'icon': Icons.timer_outlined,
        'label': 'ETA',
        'value': NavBotData.eta,
        'color': Colors.red,
        'bg': const Color(0xFFFFEBEE),
      },
    ];

    final List<Map<String, dynamic>> featureCards = [
      {
        'icon': Icons.route_rounded,
        'title': 'Path Planning',
        'subtitle': 'Smart autonomous navigation',
        'color': const Color(0xFF1F4E8C),
      },
      {
        'icon': Icons.sensors_rounded,
        'title': 'Live Sensors',
        'subtitle': 'Real-time obstacle detection',
        'color': const Color(0xFF00BCD4),
      },
      {
        'icon': Icons.battery_charging_full_rounded,
        'title': 'Auto Charge',
        'subtitle': 'Returns when battery low',
        'color': Colors.green,
      },
      {
        'icon': Icons.wifi_rounded,
        'title': 'WiFi Sync',
        'subtitle': 'Instant app sync over network',
        'color': Colors.orange,
      },
    ];

    return Scaffold(
      appBar:
          buildNavBotAppBar(context, title: 'Stats & Overview', showBack: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Live Robot Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF163A63),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Current delivery session overview',
              style: TextStyle(color: Colors.black45, fontSize: 13),
            ),
            const SizedBox(height: 14),

            // GridView.count — 2-column grid of stat Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: statCards.map((item) {
                return Card(
                  elevation: 3,
                  clipBehavior: Clip.antiAlias,
                  shadowColor: (item['color'] as Color).withValues(alpha: 0.18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: item['bg'] as Color,
                      border: Border.all(
                        color: (item['color'] as Color).withValues(alpha: 0.2),
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: (item['color'] as Color)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['value'] as String,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: item['color'] as Color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['label'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 22),

            const Text(
              'Robot Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF163A63),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'What NavBot can do',
              style: TextStyle(color: Colors.black45, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Horizontal ListView of feature Cards
            // FIX 1: Height raised from 130→152 so Card elevation shadows
            //        are not clipped by the SizedBox boundary.
            // FIX 2: Replaced Spacer() with a fixed SizedBox(height:12).
            //        Spacer() requires an unbounded flex axis, but inside a
            //        horizontal ListView the cross-axis (height) is fixed —
            //        Spacer() in that Column caused a "RenderFlex overflowed"
            //        error at runtime. Using SizedBox gives predictable spacing.
            // FIX 3: Added padding on the ListView so the first/last cards
            //        are not flush with the screen edge.
            SizedBox(
              height: 152,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(2, 2, 16, 4),
                itemCount: featureCards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final f = featureCards[index];
                  return Card(
                    elevation: 3,
                    shadowColor: (f['color'] as Color).withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: 148,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (f['color'] as Color).withValues(alpha: 0.08),
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color:
                                  (f['color'] as Color).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              f['icon'] as IconData,
                              color: f['color'] as Color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 12), // FIX: was Spacer()
                          Text(
                            f['title'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF163A63),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            f['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black45,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF163A63),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Last completed deliveries',
              style: TextStyle(color: Colors.black45, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // ListView.builder with ListTile Cards
            NavBotStore.history.isEmpty
                ? Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 40, color: Colors.black26),
                            SizedBox(height: 8),
                            Text('No recent activity',
                                style: TextStyle(color: Colors.black38)),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: NavBotStore.history.length > 5
                        ? 5
                        : NavBotStore.history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final r = NavBotStore.history[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(Icons.check_circle_rounded,
                                color: Colors.green, size: 22),
                          ),
                          title: Text(
                            '${r.from}  →  ${r.to}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Color(0xFF163A63),
                            ),
                          ),
                          subtitle: Text(
                            r.package.isEmpty ? 'No details' : r.package,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LAB 10 — ROBOT FEATURES SCREEN
// Demonstrates: SliverAppBar, SliverGrid, SliverList, SliverToBoxAdapter,
//               CustomScrollView
// ═════════════════════════════════════════════════════════════════════════════

class RobotFeaturesScreen extends StatelessWidget {
  const RobotFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> capabilities = [
      {
        'icon': Icons.radar_rounded,
        'label': 'Obstacle\nDetection',
        'color': const Color(0xFF1F4E8C)
      },
      {
        'icon': Icons.map_rounded,
        'label': 'Map\nBuilding',
        'color': const Color(0xFF00BCD4)
      },
      {
        'icon': Icons.speed_rounded,
        'label': 'Speed\nControl',
        'color': Colors.orange
      },
      {
        'icon': Icons.battery_full_rounded,
        'label': 'Battery\nMonitor',
        'color': Colors.green
      },
      {
        'icon': Icons.wifi_rounded,
        'label': 'WiFi\nControl',
        'color': Colors.deepPurple
      },
      {
        'icon': Icons.notifications_active_rounded,
        'label': 'Push\nAlerts',
        'color': Colors.red
      },
      {
        'icon': Icons.history_rounded,
        'label': 'Trip\nHistory',
        'color': Colors.teal
      },
      {
        'icon': Icons.lock_rounded,
        'label': 'Secure\nAccess',
        'color': Colors.brown
      },
    ];

    final List<Map<String, String>> specs = [
      {'label': 'Drive System', 'value': 'Differential Drive (2WD)'},
      {'label': 'Sensors', 'value': 'Ultrasonic + IR + Camera'},
      {'label': 'Navigation', 'value': 'A* Pathfinding Algorithm'},
      {'label': 'Connectivity', 'value': 'WiFi 802.11 b/g/n'},
      {'label': 'Payload', 'value': 'Up to 2 kg'},
      {'label': 'Battery', 'value': 'Li-Ion 5000mAh'},
      {'label': 'Framework', 'value': 'Flutter (Cross-platform)'},
      {'label': 'Version', 'value': 'NavBot v1.0.0'},
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // SliverAppBar — collapsing hero header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1F4E8C),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                'Robot Capabilities',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1F4E8C), Color(0xFF00BCD4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),
                      Icon(Icons.smart_toy_rounded,
                          color: Colors.white, size: 64),
                      SizedBox(height: 8),
                      Text(
                        'NavBot — Autonomous Delivery Robot',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // SliverToBoxAdapter — section title
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Core Capabilities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF163A63),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'What powers NavBot under the hood',
                    style: TextStyle(color: Colors.black45, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          // SliverGrid — 4-column capability icon cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final c = capabilities[index];
                  return Card(
                    elevation: 3,
                    shadowColor: (c['color'] as Color).withValues(alpha: 0.2),
                    // FIX: clipBehavior ensures the Container's BoxDecoration
                    // (color + border) is clipped to the Card's rounded shape.
                    // Without this, the decoration renders as a square over
                    // the Card's rounded corners.
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: (c['color'] as Color).withValues(alpha: 0.06),
                        border: Border.all(
                          color: (c['color'] as Color).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // FIX: Reduced icon container from 48→36 so it fits
                          // inside the narrower 4-column grid cells without
                          // overflowing. The card is ~(screenWidth-32-30)/4
                          // wide (~75-80px on a typical phone).
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color:
                                  (c['color'] as Color).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              c['icon'] as IconData,
                              color: c['color'] as Color,
                              size: 20, // FIX: reduced from 26→20
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              c['label'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 10, // FIX: reduced from 12→10
                                color: c['color'] as Color,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: capabilities.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85, // FIX: was 0.9 — slightly taller cells
              ),
            ),
          ),

          // SliverToBoxAdapter — tech specs section title
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Technical Specifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF163A63),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Hardware and software details',
                    style: TextStyle(color: Colors.black45, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          // SliverList — tech specs as ListTile Cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final s = specs[index];
                  final isLast = index == specs.length - 1;
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4FF),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.memory_rounded,
                          color: Color(0xFF1F4E8C),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        s['label']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      trailing: Text(
                        s['value']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Color(0xFF163A63),
                        ),
                      ),
                    ),
                  );
                },
                childCount: specs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
