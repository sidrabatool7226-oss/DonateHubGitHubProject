// ============================================================
// FILE: test/widget_test.dart (FIXED)
//
// This was the default Flutter counter-app template, still looking
// for widgets ("0", "1", a "+" icon) that don't exist anywhere in
// DonateHub. It also referenced a `MyApp` class that isn't your real
// app widget (a fake empty `MyApp` class had been added just to make
// it compile, but the test still failed at runtime).
//
// Your real app widget is DonateHubApp (see lib/main.dart), and it
// calls Firebase.initializeApp() during startup. Widget tests run
// without a real Firebase backend, so pumping DonateHubApp directly
// here would throw unless Firebase is mocked first (packages like
// firebase_auth_mocks / fake_cloud_firestore, not currently in your
// pubspec). Rather than add that setup silently, this is a genuine,
// passing smoke test that does not depend on Firebase: it checks
// that a screen from your own app (SplashScreen) renders without
// crashing.
//
// When you're ready for deeper tests (e.g. testing AuthService or a
// controller against a real Firestore call), add firebase_auth_mocks
// and fake_cloud_firestore to pubspec.yaml's dev_dependencies first.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donatehub_android_studio/screens/auth/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Just confirms the widget tree built successfully — no crash,
    // no missing widget. This does not exercise Firebase-dependent
    // navigation, which needs the mocking setup described above.
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}