// ============================================================
//  CommunityConnect — Flutter App (Backend Integrated)
//  All mock data replaced with real API calls.
//
//  pubspec.yaml — add these dependencies:
//    http: ^1.2.1
//    shared_preferences: ^2.2.3
//    google_fonts: ^6.2.1
//    google_sign_in: ^6.2.1   (for Google OAuth)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/auth_service.dart';
import 'services/event_service.dart';
import 'services/user_service.dart';
import 'services/notification_service.dart';
import 'services/chat_service.dart';
import 'services/token_service.dart';
import 'services/http_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const MyApp());
}

// ─── THEME COLOURS ───────────────────────────────────────────
const kGreen      = Color(0xFF1A5C3A);
const kGreenLight = Color(0xFF2E8B57);
const kGreenPale  = Color(0xFFE8F5EE);
const kCoral      = Color(0xFFD95F3B);
const kCoralPale  = Color(0xFFFAEDE8);
const kAmber      = Color(0xFFE8A020);
const kInk        = Color(0xFF111D13);
const kSlate      = Color(0xFF4A5568);
const kMist       = Color(0xFF8A9BA8);
const kSurface    = Color(0xFFF7F8F6);
const kCard       = Color(0xFFFFFFFF);
const kBorder     = Color(0xFFE2E8E4);

// ─── GLOBAL SESSION STATE ─────────────────────────────────────
// Populated after login — used across pages without a state manager.
class AppSession {
  static Map<String, dynamic>? user; // The logged-in user's data from backend
  static String get userName    => user?['username']  ?? '';
  static String get userEmail   => user?['email']     ?? '';
  static String get userId      => user?['_id'] ?? user?['id'] ?? '';
  static int    get points      => user?['points']    ?? 0;
}

// ════════════════════════════════════════════════════════════
//  APP ROOT
// ════════════════════════════════════════════════════════════
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CommunityConnect',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kSurface,
        colorScheme: ColorScheme.fromSeed(seedColor: kGreen, primary: kGreen, secondary: kCoral, surface: kCard),
        textTheme: GoogleFonts.dmSansTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kGreen, foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54), elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kGreen, minimumSize: const Size(double.infinity, 54),
            side: const BorderSide(color: kGreen, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: kSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGreen, width: 1.5)),
          labelStyle: GoogleFonts.dmSans(color: kMist, fontSize: 14),
          hintStyle: GoogleFonts.dmSans(color: kMist, fontSize: 14),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SPLASH — checks if user is already logged in
// ════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _scale = Tween<double>(begin: 0.75, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    _fade  = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
    _c.forward();
    _checkLoginStatus();
  }

  // If a JWT token is saved, try to load the profile and skip the auth page
  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final loggedIn = await TokenService.isLoggedIn();
    if (loggedIn) {
      try {
        final profile = await UserService.getProfile();
        AppSession.user = profile;
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainPage()));
          return;
        }
      } catch (_) {
        // Token expired — fall through to auth page
        await TokenService.clearToken();
      }
    }
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthPage()));
    }
  }

  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D3320), kGreen, Color(0xFF2E8B57)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Stack(children: [
          Positioned(top: -60, right: -60, child: _Blob(200, Colors.white, 0.05)),
          Positioned(bottom: 80, left: -80, child: _Blob(260, Colors.white, 0.04)),
          Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => Opacity(
                opacity: _fade.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 28, offset: const Offset(0, 10))],
                      ),
                      child: const Center(child: Text('🤝', style: TextStyle(fontSize: 48))),
                    ),
                    const SizedBox(height: 28),
                    Text('CommunityConnect',
                      style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 8),
                    Text('Volunteer · Organise · Belong',
                      style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white.withOpacity(0.65), letterSpacing: 1),
                    ),
                    const SizedBox(height: 56),
                    SizedBox(width: 28, height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withOpacity(0.6)),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size; final Color color; final double opacity;
  const _Blob(this.size, this.color, this.opacity);
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(opacity)),
  );
}

// ════════════════════════════════════════════════════════════
//  AUTH PAGE
// ════════════════════════════════════════════════════════════
class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0D3320), kGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          padding: EdgeInsets.fromLTRB(28, MediaQuery.of(context).padding.top + 36, 28, 44),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Center(child: Text('🤝', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 16),
            Text('CommunityConnect',
              style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3),
            ),
            const SizedBox(height: 6),
            Text('Volunteer · Organise · Belong',
              style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white.withOpacity(0.6), letterSpacing: 0.5),
            ),
            const SizedBox(height: 28),
            Text('Connect.\nVolunteer.\nMake impact.',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, height: 1.15),
            ),
            const SizedBox(height: 10),
            Text('Join thousands making a difference locally',
              style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white.withOpacity(0.6)),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 8),
              ElevatedButton(
                // Google Sign-In: implement with google_sign_in package
                // and pass the idToken to AuthService.googleLogin(idToken)
                onPressed: () => _showSnack(context, 'Add google_sign_in package to enable Google login'),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'serif', color: Colors.white)),
                  const SizedBox(width: 10),
                  Text('Continue with Google', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Divider(color: kBorder)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('or', style: GoogleFonts.dmSans(color: kMist, fontSize: 13))),
                Expanded(child: Divider(color: kBorder)),
              ]),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                child: Text('Login with Email', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage())),
                child: Text("Don't have an account? Sign up",
                  style: GoogleFonts.dmSans(color: kGreen, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              Text('By continuing, you agree to our Terms & Privacy Policy',
                style: GoogleFonts.dmSans(fontSize: 11, color: kMist, height: 1.4), textAlign: TextAlign.center),
            ]),
          ),
        ),
      ]),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ════════════════════════════════════════════════════════════
//  SIGNUP PAGE — calls AuthService.signup()
// ════════════════════════════════════════════════════════════
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true, _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService.signup(
        username: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      AppSession.user = user;
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainPage()), (r) => false);
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Network error. Is the server running?'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: _buildAppBar(context, 'Create Account'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          Text('Join the community', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 6),
          Text('Fill in your details to get started', style: GoogleFonts.dmSans(fontSize: 14, color: kMist)),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kCoralPale, borderRadius: BorderRadius.circular(10), border: Border.all(color: kCoral.withOpacity(0.3))),
              child: Text(_error!, style: GoogleFonts.dmSans(color: kCoral, fontSize: 13)),
            ),
          ],
          const SizedBox(height: 24),
          _FieldLabel('Full Name'),
          TextFormField(
            controller: _nameCtrl, textInputAction: TextInputAction.next,
            style: GoogleFonts.dmSans(color: kInk),
            decoration: const InputDecoration(hintText: 'e.g. Anika Kumar', prefixIcon: Icon(Icons.person_outline_rounded, color: kGreen, size: 20)),
            validator: (v) => (v == null || v.isEmpty) ? 'Enter your name' : null,
          ),
          const SizedBox(height: 16),
          _FieldLabel('Email Address'),
          TextFormField(
            controller: _emailCtrl, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
            style: GoogleFonts.dmSans(color: kInk),
            decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.mail_outline_rounded, color: kGreen, size: 20)),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your email';
              if (!v.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _FieldLabel('Password'),
          TextFormField(
            controller: _passCtrl, obscureText: _obscure, textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            style: GoogleFonts.dmSans(color: kInk),
            decoration: InputDecoration(
              hintText: 'Min. 6 characters',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: kGreen, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: kMist, size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a password';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 28),
          _loading
              ? const Center(child: CircularProgressIndicator(color: kGreen))
              : ElevatedButton(onPressed: _submit, child: Text('Create Account', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15))),
        ])),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  LOGIN PAGE — calls AuthService.login()
// ════════════════════════════════════════════════════════════
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true, _loading = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      AppSession.user = user;
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainPage()), (r) => false);
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Network error. Is the server running?'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: _buildAppBar(context, 'Login'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          Text('Welcome back!', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 6),
          Text('Log in to continue volunteering', style: GoogleFonts.dmSans(fontSize: 14, color: kMist)),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kCoralPale, borderRadius: BorderRadius.circular(10), border: Border.all(color: kCoral.withOpacity(0.3))),
              child: Text(_error!, style: GoogleFonts.dmSans(color: kCoral, fontSize: 13)),
            ),
          ],
          const SizedBox(height: 24),
          _FieldLabel('Email Address'),
          TextFormField(
            controller: _emailCtrl, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
            style: GoogleFonts.dmSans(color: kInk),
            decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.mail_outline_rounded, color: kGreen, size: 20)),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your email';
              if (!v.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _FieldLabel('Password'),
          TextFormField(
            controller: _passCtrl, obscureText: _obscure, textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            style: GoogleFonts.dmSans(color: kInk),
            decoration: InputDecoration(
              hintText: 'Your password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: kGreen, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: kMist, size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () {}, child: Text('Forgot password?', style: GoogleFonts.dmSans(color: kGreen, fontSize: 13, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          _loading
              ? const Center(child: CircularProgressIndicator(color: kGreen))
              : ElevatedButton(onPressed: _login, child: Text('Login', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15))),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage())),
              child: Text("Don't have an account? Sign up",
                style: GoogleFonts.dmSans(color: kGreen, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ])),
      ),
    );
  }
}

AppBar _buildAppBar(BuildContext context, String title) => AppBar(
  backgroundColor: Colors.white, elevation: 0, surfaceTintColor: Colors.transparent,
  leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kGreen, size: 20), onPressed: () => Navigator.pop(context)),
  title: Text(title, style: GoogleFonts.playfairDisplay(color: kInk, fontWeight: FontWeight.w700, fontSize: 18)),
  bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: kBorder)),
);

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: kSlate)),
  );
}

// ════════════════════════════════════════════════════════════
//  MAIN SCAFFOLD
// ════════════════════════════════════════════════════════════
class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // Default tab is Search (index 1) as per requirements
  int _idx = 1;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onTabChange: (i) => setState(() => _idx = i)),
      const SearchPage(),
      const NotificationPage(),
      const MessagesPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _idx, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kCard,
          border: Border(top: BorderSide(color: kBorder)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, -3))],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _NavItem(icon: Icons.home_filled, label: 'Home', active: _idx == 0, onTap: () => setState(() => _idx = 0)),
              _NavItem(icon: Icons.search_rounded, label: 'Discover', active: _idx == 1, onTap: () => setState(() => _idx = 1)),
              _NavItem(icon: Icons.notifications_rounded, label: 'Alerts', active: _idx == 2, onTap: () => setState(() => _idx = 2)),
              _NavItem(icon: Icons.chat_bubble_rounded, label: 'Messages', active: _idx == 3, onTap: () => setState(() => _idx = 3)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final bool active; final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap, behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 27, color: active ? kGreen : kMist),
        const SizedBox(height: 3),
        Text(label, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? kGreen : kMist)),
        const SizedBox(height: 2),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 16 : 0, height: 3,
          decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(2)),
        ),
      ]),
    ),
  );
}

PreferredSizeWidget buildMainAppBar(BuildContext context, String title) => AppBar(
  backgroundColor: kCard, elevation: 0, surfaceTintColor: Colors.transparent, centerTitle: false,
  title: Text(title, style: GoogleFonts.playfairDisplay(color: kInk, fontWeight: FontWeight.w700, fontSize: 20)),
  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: kGreen,
            boxShadow: [BoxShadow(color: kGreen.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Center(
            child: Text(
              AppSession.userName.isNotEmpty ? AppSession.userName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase() : '?',
              style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    ),
  ],
  bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: kBorder)),
);

// ════════════════════════════════════════════════════════════
//  HOME PAGE — loads featured event + organized events from API
// ════════════════════════════════════════════════════════════
class HomePage extends StatefulWidget {
  final void Function(int) onTabChange;
  const HomePage({super.key, required this.onTabChange});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _featuredEvent;
  List<dynamic> _myEvents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        EventService.getFeaturedEvent(),
        EventService.getUpcomingEvents(),
      ]);
      setState(() {
        _featuredEvent = results[0] as Map<String, dynamic>?;
        // Filter to show only events the logged-in user organized
        final all = results[1] as List<dynamic>;
        _myEvents = all.where((e) {
          final org = e['organizer'];
          final orgId = org is Map ? org['_id'] ?? org['id'] : org;
          return orgId == AppSession.userId;
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Failed to load. Tap to retry.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: buildMainAppBar(context, 'Home'),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: kGreen))
        : _error != null
          ? Center(child: GestureDetector(onTap: () { setState(() { _loading = true; _error = null; }); _load(); },
              child: Text(_error!, style: GoogleFonts.dmSans(color: kCoral))))
          : RefreshIndicator(
              onRefresh: _load, color: kGreen,
              child: ListView(children: [

                // Hero banner
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF0D3320), kGreen, kGreenLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Good morning 👋', style: GoogleFonts.dmSans(color: Colors.white.withOpacity(0.65), fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(AppSession.userName, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Row(children: [
                      _HeroStat('${AppSession.points}', 'Points earned'),
                      const SizedBox(width: 10),
                      _HeroStat('${_myEvents.length}', 'Organised'),
                    ]),
                  ]),
                ),

                // Featured event
                if (_featuredEvent != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text('Featured Event', style: GoogleFonts.playfairDisplay(fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: _ApiEventCard(event: _featuredEvent!, showBadge: 'Featured ⭐'),
                  ),
                ],

                // Organise button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Your Events', style: GoogleFonts.playfairDisplay(fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
                    GestureDetector(
                      onTap: () => _showCreateEventSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: kGreenPale, borderRadius: BorderRadius.circular(8), border: Border.all(color: kGreen.withOpacity(0.3))),
                        child: Row(children: [
                          const Icon(Icons.add_rounded, size: 14, color: kGreen),
                          const SizedBox(width: 4),
                          Text('New Event', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: kGreen)),
                        ]),
                      ),
                    ),
                  ]),
                ),

                if (_myEvents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
                      child: Column(children: [
                        const Text('📭', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 10),
                        Text("You haven't organised any events yet", style: GoogleFonts.dmSans(fontSize: 14, color: kMist)),
                      ]),
                    ),
                  )
                else
                  ..._myEvents.map((e) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _ApiEventCard(event: e as Map<String, dynamic>),
                  )),

                const SizedBox(height: 24),
              ]),
            ),
    );
  }

  void _showCreateEventSheet(BuildContext context) {
    final titleCtrl    = TextEditingController();
    final locationCtrl = TextEditingController();
    final dateCtrl     = TextEditingController();
    final descCtrl     = TextEditingController();
    bool creating = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx2).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Create Event', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 20),
          TextField(controller: titleCtrl, style: GoogleFonts.dmSans(color: kInk),
            decoration: const InputDecoration(labelText: 'Event title *', prefixIcon: Icon(Icons.event_rounded, color: kGreen, size: 20))),
          const SizedBox(height: 12),
          TextField(controller: locationCtrl, style: GoogleFonts.dmSans(color: kInk),
            decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.place_outlined, color: kGreen, size: 20))),
          const SizedBox(height: 12),
          TextField(controller: dateCtrl, style: GoogleFonts.dmSans(color: kInk),
            decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD) *', prefixIcon: Icon(Icons.calendar_today_rounded, color: kGreen, size: 20))),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, style: GoogleFonts.dmSans(color: kInk), maxLines: 2,
            decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.notes_rounded, color: kGreen, size: 20))),
          const SizedBox(height: 20),
          creating
            ? const Center(child: CircularProgressIndicator(color: kGreen))
            : ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || dateCtrl.text.trim().isEmpty) return;
                setS(() => creating = true);
                try {
                  await EventService.createEvent(
                    title: titleCtrl.text.trim(),
                    date: dateCtrl.text.trim(),
                    location: locationCtrl.text.trim().isNotEmpty ? locationCtrl.text.trim() : null,
                    description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                  );
                  if (ctx2.mounted) Navigator.pop(ctx2);
                  _load(); // Refresh list
                } catch (_) {
                  setS(() => creating = false);
                }
              },
              child: Text('Create Event', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
        ]),
      )),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value, label;
  const _HeroStat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        Text(label, style: GoogleFonts.dmSans(color: Colors.white.withOpacity(0.6), fontSize: 10), overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

// ─── Event card backed by real API data ──────────────────────
class _ApiEventCard extends StatefulWidget {
  final Map<String, dynamic> event;
  final String? showBadge;
  const _ApiEventCard({required this.event, this.showBadge});
  @override State<_ApiEventCard> createState() => _ApiEventCardState();
}

class _ApiEventCardState extends State<_ApiEventCard> {
  bool _joining = false;
  bool _joined  = false;

  String get _eventId => widget.event['_id'] ?? widget.event['id'] ?? '';
  String get _title   => widget.event['title'] ?? 'Untitled Event';
  String get _location => widget.event['location'] ?? 'Location TBD';
  String get _date {
    final raw = widget.event['date'];
    if (raw == null) return 'Date TBD';
    try { return raw.toString().substring(0, 10); } catch (_) { return raw.toString(); }
  }
  String get _category => widget.event['category'] ?? 'General';
  String get _organizerName {
    final org = widget.event['organizer'];
    if (org is Map) return org['username'] ?? 'Organizer';
    return 'Organizer';
  }

  Future<void> _register() async {
    setState(() => _joining = true);
    try {
      await EventService.registerForEvent(_eventId);
      setState(() { _joined = true; _joining = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered! +10 points earned 🎉'), backgroundColor: kGreen),
        );
      }
    } on ApiException catch (e) {
      setState(() => _joining = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          height: 80, width: double.infinity,
          decoration: BoxDecoration(color: kGreenPale, borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
          child: Stack(children: [
            const Center(child: Text('📅', style: TextStyle(fontSize: 40))),
            if (widget.showBadge != null)
              Positioned(left: 12, bottom: 10, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(7)),
                child: Text(widget.showBadge!, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              )),
            Positioned(right: 12, top: 10, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Text(_category, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: kSlate)),
            )),
          ]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Text(_title, style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w700, color: kInk))),
        Padding(padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
          child: Row(children: [
            const Icon(Icons.schedule_rounded, size: 13, color: kMist),
            const SizedBox(width: 4),
            Text(_date, style: GoogleFonts.dmSans(fontSize: 12, color: kMist)),
            const SizedBox(width: 12),
            const Icon(Icons.place_rounded, size: 13, color: kMist),
            const SizedBox(width: 4),
            Expanded(child: Text(_location, style: GoogleFonts.dmSans(fontSize: 12, color: kMist), overflow: TextOverflow.ellipsis)),
          ]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
          child: Text('by $_organizerName', style: GoogleFonts.dmSans(fontSize: 11, color: kMist))),
        Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Row(children: [
            const Spacer(),
            _joining
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: kGreen))
              : GestureDetector(
                  onTap: _joined ? null : _register,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                    decoration: BoxDecoration(
                      color: _joined ? kGreenPale : kGreen,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _joined ? kGreen : Colors.transparent),
                    ),
                    child: Text(_joined ? 'Joined ✓' : 'Join',
                      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: _joined ? kGreen : Colors.white)),
                  ),
                ),
          ]),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SEARCH PAGE — loads from /api/events/search
// ════════════════════════════════════════════════════════════
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _ctrl = TextEditingController();
  List<dynamic> _events = [];
  bool _loading = true;
  int _filterIndex = 0;

  final _filters = [
    {'label': 'All',         'category': null},
    {'label': 'Environment', 'category': 'Environment'},
    {'label': 'Health',      'category': 'Health'},
    {'label': 'Education',   'category': 'Education'},
    {'label': 'Food',        'category': 'Food'},
    {'label': 'Tech',        'category': 'Tech'},
  ];

  @override
  void initState() { super.initState(); _search(); }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final category = _filters[_filterIndex]['category'];
      final events = await EventService.searchEvents(
        q: _ctrl.text.trim().isNotEmpty ? _ctrl.text.trim() : null,
        category: category,
      );
      setState(() { _events = events; _loading = false; });
    } catch (_) {
      setState(() { _events = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: buildMainAppBar(context, 'Discover'),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: TextField(
            controller: _ctrl,
            onSubmitted: (_) => _search(),
            onChanged: (v) { if (v.isEmpty) _search(); },
            style: GoogleFonts.dmSans(color: kInk),
            decoration: InputDecoration(
              hintText: 'Search events...',
              prefixIcon: const Icon(Icons.search_rounded, color: kGreen, size: 22),
              suffixIcon: IconButton(icon: const Icon(Icons.send_rounded, color: kGreen, size: 20), onPressed: _search),
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            itemCount: _filters.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () { setState(() => _filterIndex = i); _search(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: _filterIndex == i ? kGreen : kCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _filterIndex == i ? kGreen : kBorder),
                ),
                child: Text(_filters[i]['label']!, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: _filterIndex == i ? Colors.white : kSlate)),
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: kGreen))
            : _events.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🔍', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('No events found', style: GoogleFonts.dmSans(fontSize: 15, color: kMist)),
                ]))
              : RefreshIndicator(
                  onRefresh: _search, color: kGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ApiEventCard(event: _events[i] as Map<String, dynamic>),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  NOTIFICATION PAGE — loads from /api/notifications
// ════════════════════════════════════════════════════════════
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});
  @override State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> _notifs = [];
  int _unreadCount = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await NotificationService.getNotifications();
      setState(() {
        _notifs = data['notifications'] as List<dynamic>? ?? [];
        _unreadCount = data['unreadCount'] as int? ?? 0;
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllAsRead();
    _load();
  }

  String _typeIcon(String? type) {
    switch (type) {
      case 'confirmation': return '✅';
      case 'reminder':     return '⏰';
      case 'update':       return '📢';
      default:             return '🔔';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kCard, elevation: 0, surfaceTintColor: Colors.transparent, centerTitle: false,
        title: Text('Alerts', style: GoogleFonts.playfairDisplay(color: kInk, fontWeight: FontWeight.w700, fontSize: 20)),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read', style: GoogleFonts.dmSans(color: kGreen, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(shape: BoxShape.circle, color: kGreen,
                  boxShadow: [BoxShadow(color: kGreen.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 2))]),
                child: Center(child: Text(
                  AppSession.userName.isNotEmpty ? AppSession.userName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase() : '?',
                  style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                )),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: kBorder)),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: kGreen))
        : _notifs.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🔕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('No notifications yet', style: GoogleFonts.dmSans(fontSize: 15, color: kMist)),
            ]))
          : RefreshIndicator(
              onRefresh: _load, color: kGreen,
              child: ListView.separated(
                itemCount: _notifs.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: kBorder),
                itemBuilder: (_, i) {
                  final n = _notifs[i] as Map<String, dynamic>;
                  final unread = !(n['isRead'] as bool? ?? true);
                  return GestureDetector(
                    onTap: () async {
                      if (unread) {
                        await NotificationService.markAsRead(n['_id'] ?? n['id'] ?? '');
                        _load();
                      }
                    },
                    child: Container(
                      color: unread ? kGreenPale.withOpacity(0.5) : kCard,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        leading: Container(
                          width: 46, height: 46,
                          decoration: const BoxDecoration(color: kGreenPale, shape: BoxShape.circle),
                          child: Center(child: Text(_typeIcon(n['type'] as String?), style: const TextStyle(fontSize: 22))),
                        ),
                        title: Text(n['title'] as String? ?? '', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (n['body'] != null && (n['body'] as String).isNotEmpty)
                            Text(n['body'] as String, style: GoogleFonts.dmSans(fontSize: 12, color: kSlate, height: 1.4)),
                          const SizedBox(height: 4),
                          Text(
                            (n['createdAt'] as String? ?? '').isNotEmpty
                              ? (n['createdAt'] as String).substring(0, 10)
                              : '',
                            style: GoogleFonts.dmSans(fontSize: 11, color: kMist),
                          ),
                        ]),
                        trailing: unread ? Container(width: 9, height: 9, decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle)) : null,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  MESSAGES PAGE — loads from /api/chats
// ════════════════════════════════════════════════════════════
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});
  @override State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<dynamic> _chats = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final chats = await ChatService.getChatList();
      setState(() { _chats = chats; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    return name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: buildMainAppBar(context, 'Messages'),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: kGreen))
        : _chats.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('💬', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('No messages yet', style: GoogleFonts.dmSans(fontSize: 15, color: kMist)),
              const SizedBox(height: 8),
              Text('Register for an event and chat with the organizer', style: GoogleFonts.dmSans(fontSize: 13, color: kMist), textAlign: TextAlign.center),
            ]))
          : RefreshIndicator(
              onRefresh: _load, color: kGreen,
              child: ListView.separated(
                itemCount: _chats.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: kBorder, indent: 80),
                itemBuilder: (_, i) {
                  final chat = _chats[i] as Map<String, dynamic>;
                  final other = chat['other_username'] ?? chat['organizer']?['username'] ?? chat['user']?['username'] ?? 'User';
                  final preview = chat['lastMessage'] ?? 'No messages yet';
                  final chatId  = chat['_id'] ?? chat['id'] ?? '';

                  return Container(
                    color: kCard,
                    child: ListTile(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ChatDetailPage(chatId: chatId, otherName: other),
                      )).then((_) => _load()),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: CircleAvatar(
                        radius: 26, backgroundColor: kGreen,
                        child: Text(_initials(other), style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                      ),
                      title: Text(other, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
                      subtitle: Text(preview, style: GoogleFonts.dmSans(fontSize: 12, color: kMist), overflow: TextOverflow.ellipsis),
                      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(
                          chat['lastMessageAt'] != null ? (chat['lastMessageAt'] as String).substring(0, 10) : '',
                          style: GoogleFonts.dmSans(fontSize: 11, color: kMist),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CHAT DETAIL PAGE — sends/receives real messages
// ════════════════════════════════════════════════════════════
class ChatDetailPage extends StatefulWidget {
  final String chatId, otherName;
  const ChatDetailPage({super.key, required this.chatId, required this.otherName});
  @override State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<dynamic> _messages = [];
  bool _loading = true, _sending = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final msgs = await ChatService.getMessages(widget.chatId);
      setState(() { _messages = msgs; _loading = false; });
      _scrollToBottom();
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    setState(() => _sending = true);
    try {
      await ChatService.sendMessage(widget.chatId, text);
      await _load();
    } catch (_) {}
    setState(() => _sending = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: _buildAppBar(context, widget.otherName),
      body: Column(children: [
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: kGreen))
            : _messages.isEmpty
              ? Center(child: Text('Start the conversation!', style: GoogleFonts.dmSans(color: kMist)))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg = _messages[i] as Map<String, dynamic>;
                    final senderId = msg['sender'] is Map ? msg['sender']['_id'] ?? msg['sender']['id'] : msg['sender'];
                    final isMe = senderId == AppSession.userId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                        decoration: BoxDecoration(
                          color: isMe ? kGreen : kCard,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe ? const Radius.circular(4) : null,
                            bottomLeft: !isMe ? const Radius.circular(4) : null,
                          ),
                          border: isMe ? null : Border.all(color: kBorder),
                        ),
                        child: Text(msg['content'] as String? ?? '',
                          style: GoogleFonts.dmSans(fontSize: 14, color: isMe ? Colors.white : kInk, height: 1.4)),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
          color: kCard,
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                style: GoogleFonts.dmSans(color: kInk),
                decoration: InputDecoration(hintText: 'Type a message...', contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: kGreen, width: 1.5)),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: kGreen, shape: BoxShape.circle),
                child: _sending
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  PROFILE PAGE — loads real data from /api/users/profile
// ════════════════════════════════════════════════════════════
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;
  List<dynamic> _attended  = [];
  List<dynamic> _organized = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        UserService.getProfile(),
        UserService.getAttendedEvents(),
        UserService.getOrganizedEvents(),
      ]);
      setState(() {
        _profile  = results[0] as Map<String, dynamic>;
        _attended  = results[1] as List<dynamic>;
        _organized = results[2] as List<dynamic>;
        AppSession.user = _profile; // keep session in sync
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  String get _initials {
    final name = _profile?['username'] ?? AppSession.userName;
    return name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
  }

  Future<void> _logout() async {
    await AuthService.logout();
    AppSession.user = null;
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthPage()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: kGreen))
        : CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: 220, pinned: true,
            backgroundColor: kGreen, surfaceTintColor: Colors.transparent,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF0D3320), kGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: kGreenLight, border: Border.all(color: Colors.white.withOpacity(0.4), width: 3)),
                    child: Center(child: Text(_initials, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(height: 10),
                  Text(_profile?['username'] ?? '', style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(_profile?['email'] ?? '', style: GoogleFonts.dmSans(color: Colors.white.withOpacity(0.65), fontSize: 12)),
                ])),
              ),
            ),
          ),

          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [

              // Stats
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
                child: Row(children: [
                  _PStat('${_attended.length}',  'Attended'),
                  _PDivider(),
                  _PStat('${_organized.length}', 'Organised'),
                  _PDivider(),
                  _PStat('${_profile?['points'] ?? 0}', 'Points'),
                ]),
              ),
              const SizedBox(height: 14),

              // Profile details
              _PSection(title: 'Account Details', child: Column(children: [
                _InfoRow(Icons.person_outline_rounded,  'Username', _profile?['username'] ?? ''),
                _InfoRow(Icons.mail_outline_rounded,    'Email',    _profile?['email']    ?? ''),
                _InfoRow(Icons.star_outline_rounded,    'Points',   '${_profile?['points'] ?? 0} pts', showDivider: false),
              ])),
              const SizedBox(height: 14),

              // Attended events
              if (_attended.isNotEmpty) ...[
                _PSection(title: 'Events Attended (${_attended.length})', child: Column(
                  children: _attended.take(3).map((e) {
                    final event = e as Map<String, dynamic>;
                    return _InfoRow(Icons.event_available_rounded, event['title'] ?? '', event['date']?.toString().substring(0, 10) ?? '');
                  }).toList(),
                )),
                const SizedBox(height: 14),
              ],

              // Logout
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: Text('Sign out?', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 20)),
                    content: Text('You will be returned to the login screen.', style: GoogleFonts.dmSans(color: kSlate, fontSize: 14)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.dmSans(color: kMist))),
                      ElevatedButton(
                        onPressed: () { Navigator.pop(ctx); _logout(); },
                        style: ElevatedButton.styleFrom(backgroundColor: kCoral, minimumSize: const Size(0, 0), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                        child: Text('Sign out', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(color: kCoralPale, borderRadius: BorderRadius.circular(14), border: Border.all(color: kCoral.withOpacity(0.3))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.logout_rounded, size: 18, color: kCoral),
                    const SizedBox(width: 8),
                    Text('Sign out', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: kCoral)),
                  ]),
                ),
              ),
              const SizedBox(height: 32),
            ]),
          )),
        ]),
    );
  }
}

class _PStat extends StatelessWidget {
  final String value, label;
  const _PStat(this.value, this.label);
  @override Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: kGreen)),
    const SizedBox(height: 4),
    Text(label, textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 11, color: kMist)),
  ]));
}

class _PDivider extends StatelessWidget {
  @override Widget build(BuildContext context) => Container(width: 1, height: 40, color: kBorder);
}

class _PSection extends StatelessWidget {
  final String title; final Widget child;
  const _PSection({required this.title, required this.child});
  @override Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        child: Text(title.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w800, color: kMist, letterSpacing: 0.8))),
      child,
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String label, value; final bool showDivider;
  const _InfoRow(this.icon, this.label, this.value, {this.showDivider = true});
  @override Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 12), child: Row(children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: kGreenPale, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: kGreen, size: 17)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: kMist)),
        Text(value, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: kInk)),
      ])),
    ])),
    if (showDivider) Divider(height: 1, color: kBorder, indent: 60),
  ]);
}
