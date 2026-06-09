import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'screens/donor/donate_funds_screen.dart';
import 'screens/donor/home_screen.dart';
import 'screens/donor/category_screen.dart';
import 'package:donatehub_android_studio/screens/donor/donate_form_screen.dart';

// Auth screens
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';

// ✅ STEP 1: Yahan apna Admin Dashboard import karein
import 'screens/admin/admin_dashboard.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const DonateHubApp());
}

class DonateHubApp extends StatelessWidget {
  const DonateHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DonateHub',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D6A4F),
        ),
        fontFamily: 'Roboto',
      ),

      // App starts at splash screen
      initialRoute: '/',

      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/donate_items': (context) => const CategorySelectionScreen(),

        // ✅ FIXED: Asli Admin Dashboard screen yahan connect ho gayi
        '/admin_dashboard': (context) => const AdminDashboard(),

        '/donate_funds': (context) => const DonateFundsScreen(),

        // Donor dashboard
        '/donor_dashboard': (context) => HomeScreen(),

        // Volunteers placeholders (Aap inhein baad mein real screens se replace kar sakti hain)
        '/volunteer_form': (context) => const _PlaceholderScreen(title: 'Volunteer Form'),
        '/volunteer_dashboard': (context) => const _PlaceholderScreen(title: 'Volunteer Dashboard'),
      },
    );
  }
}

// ── Temporary placeholder screen ─────────────────────────────
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming soon — build this screen next!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}