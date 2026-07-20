import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:g_l_t_final/screens/adminDashboard_screen.dart';
import 'package:g_l_t_final/screens/intro_screen.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const GulfLimousineApp());
}

class GulfLimousineApp extends StatelessWidget {
  const GulfLimousineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

/// Restores session if already signed in; otherwise shows intro.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _resolveHome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const IntroScreen();

    try {
      await NotificationService.instance.initialize();
    } catch (_) {}

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = doc.data()?['role']?.toString() ?? 'user';
      if (role == 'admin') return const AdminDashboard();
      return const DashboardScreen();
    } catch (_) {
      return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolveHome(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!;
      },
    );
  }
}
