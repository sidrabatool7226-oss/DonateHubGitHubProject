import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // NEW
import 'controllers/theme_controller.dart'; // NEW
import 'theme/app_theme.dart'; // NEW
import 'services/fcm_service.dart';
import 'screens/admin/screens/utilization_detail_screen.dart';
import 'screens/admin/screens/create_utilization_screen.dart';
import 'screens/donor/impact_screen.dart';
import 'firebase_options.dart';
import 'bindings/initial_binding.dart';
import 'screens/donor/donor_dashboard.dart';
import 'screens/donor/donor_donations_tab.dart';
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
import 'screens/manager/tabs/manager_home_tab.dart';
import 'screens/manager/manager_dashboard.dart';
import 'screens/volunteer/volunteer_registration_form_screen.dart';
import 'screens/volunteer/verification_status_screen.dart';
import 'screens/volunteer/volunteer_dashboard.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NEW — GetStorage init, required before any read/write
  await GetStorage.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  await FcmService().initialize();

  // NEW — theme controller must exist before GetMaterialApp builds
  Get.put(ThemeController(), permanent: true);

  runApp(const DonateHubApp());
}

class DonateHubApp extends StatelessWidget {
  const DonateHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    // NEW — Obx wraps GetMaterialApp so theme changes rebuild instantly,
    // app-wide, without requiring a restart.
    return Obx(() => GetMaterialApp(
      title: 'DonateHub',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.flutterThemeMode,
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/signup', page: () => const SignupScreen()),
        GetPage(name: '/donate_items', page: () => const CategorySelectionScreen()),
        GetPage(name: '/donate_funds', page: () => const DonateFundsScreen()),
        GetPage(name: '/admin_dashboard', page: () => const AdminDashboard()),
        GetPage(name: '/admin_profile', page: () => const AdminProfileScreen()),
        GetPage(name: '/utilization_detail', page: () => UtilizationDetailScreen(data: {})),
        GetPage(name: '/create_utilization', page: () => CreateUtilizationScreen()),
        GetPage(name: '/donor_impact', page: () => const DonorImpactScreen()),
        GetPage(name: '/donor_dashboard', page: () => const DonorDashboard()),
        GetPage(name: '/donation_detail', page: () => DonationDetailScreen(docId: '', data: {})),
        GetPage(name: '/manager_dashboard', page: () => const ManagerDashboard()),
        GetPage(name: '/volunteer_form', page: () => const VolunteerRegistrationFormScreen()),
        GetPage(name: '/verification_status', page: () => const VerificationStatusScreen()),
        GetPage(name: '/volunteer_dashboard', page: () => const VolunteerDashboard()),
      ],
    ));
  }
}