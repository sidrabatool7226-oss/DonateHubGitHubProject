import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'screens/admin/screens/utilization_detail_screen.dart';
import 'screens/admin/screens/create_utilization_screen.dart';
import 'screens/donor/impact_screen.dart';
import 'firebase_options.dart';
import 'bindings/initial_binding.dart';
import 'screens/donor/donor_dashboard.dart';
import 'screens/donor/donor_donations_tab.dart';
// Existing screens — yeh sab same rahein ge
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/donor/home_screen.dart';
import 'screens/donor/category_screen.dart';
import 'screens/donor/donate_funds_screen.dart';
import 'screens/donor/donate_form_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/screens/admin_profile_screen.dart';
// Background FCM handler — main() se bahar hona zaroori hai
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait mode lock
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Firebase initialize
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM background handler register
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // FCM permission maango
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const DonateHubApp());
}

class DonateHubApp extends StatelessWidget {
  const DonateHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(               // MaterialApp → GetMaterialApp
      title: 'DonateHub',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),  // GetX controllers register

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D6A4F),
        ),
        fontFamily: 'Roboto',
      ),

      // Existing routes — sab same rakho
      initialRoute: '/',
      getPages: [
        GetPage(name: '/',                    page: () => const SplashScreen()),
        GetPage(name: '/login',               page: () => const LoginScreen()),
        GetPage(name: '/signup',              page: () => const SignupScreen()),
        GetPage(name: '/donor_dashboard',     page: () => HomeScreen()),
        GetPage(name: '/donate_items',        page: () => const CategorySelectionScreen()),
        GetPage(name: '/donate_funds',        page: () => const DonateFundsScreen()),
        GetPage(name: '/admin_dashboard',     page: () => const AdminDashboard()),
        GetPage(
          name: '/admin_profile',
          page: () => const AdminProfileScreen(),
        ),
        GetPage(
          name: '/utilization_detail',
          page: () => UtilizationDetailScreen(data: {}),
        ),
        GetPage(
          name: '/create_utilization',
          page: () => CreateUtilizationScreen(),
        ),
        GetPage(
          name: '/donor_impact',
          page: () => const DonorImpactScreen(),
        ),
        GetPage(
          name: '/donor_dashboard',
          page: () => const DonorDashboard(),
        ),
        GetPage(
          name: '/donation_detail',
          page: () => DonationDetailScreen(docId: '', data: {}),
        ),
        // Placeholder routes — baad mein real screens se replace karein ge
        GetPage(name: '/manager_dashboard',   page: () => const _PlaceholderScreen(title: 'Manager Dashboard')),
        GetPage(name: '/volunteer_dashboard', page: () => const _PlaceholderScreen(title: 'Volunteer Dashboard')),
        GetPage(name: '/volunteer_form',      page: () => const _PlaceholderScreen(title: 'Volunteer Form')),
        GetPage(name: '/verification_status', page: () => const _PlaceholderScreen(title: 'Verification Status')),
      ],
    );
  }
}

// Placeholder — yeh baad mein real screens se replace hoga
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
            Text(title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Coming soon!',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}