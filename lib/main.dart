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

// ✅ Manager Dashboard import
import 'screens/Manager/manager_dashboard.dart';

// ✅ Volunteer form import
import 'screens/volunteer/volunteer_details_form.dart';

// ✅ Volunteer dashboard import (NEW)
import 'screens/volunteer/volunteer_home_screen.dart';

// ✅ Volunteer pending-approval screen import (NEW)
import 'screens/volunteer/pending_approval_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

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

      initialRoute: '/',

      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/donate_items': (context) => const CategorySelectionScreen(),

        '/admin_dashboard': (context) => const AdminDashboard(),

        '/donate_funds': (context) => const DonateFundsScreen(),

        '/donor_dashboard': (context) => HomeScreen(),

        '/manager_dashboard': (context) => const ManagerDashboard(),

        '/volunteer_form': (context) => const VolunteerDetailsForm(),

        // 👇 FIXED: ab placeholder ki jaga real dashboard khulega
        '/volunteer_dashboard': (context) => const VolunteerHomeScreen(),

        // 👇 NEW: approval ka wait wali screen
        '/pending': (context) => PendingApprovalScreen(),
      },
    );
  }
}