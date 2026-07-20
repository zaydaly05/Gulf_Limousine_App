import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:g_l_t_final/screens/adminDashboard_screen.dart';
import 'dashboard_screen.dart';
import 'forgot_password.dart';
import 'signup_screen.dart';
import '../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    signInOption: SignInOption.standard,
  );

  /// 🔐 EMAIL LOGIN
  Future<void> _login(BuildContext context) async {
    try {
      setState(() => _isLoading = true);

      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _handleUserNavigation(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Login failed");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔥 GOOGLE LOGIN (ALWAYS SHOW ACCOUNT PICKER)
  Future<void> _loginWithGoogle() async {
    try {
      setState(() => _isLoading = true);

      // ✅ Clear previously selected account
      await _googleSignIn.signOut();

      // Show account chooser
      final GoogleSignInAccount? googleUser =
      await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      await _createUserIfNotExists(userCredential.user!);
      await _handleUserNavigation(userCredential.user!);
    } catch (e) {
      print("GOOGLE ERROR: $e");
      _showError("Google Sign-In failed");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 📦 Create Firestore user if first login
  Future<void> _createUserIfNotExists(User user) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        'name': user.displayName ?? user.email?.split('@').first ?? 'User',
        'email': user.email,
        'phone': '',
        'phone_number': '',
        'role': 'user',
        'auth_provider': 'google',
        'created_at': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final data = userDoc.data() ?? {};
    final updates = <String, dynamic>{};

    if ((data['name'] == null || data['name'].toString().isEmpty) &&
        user.displayName != null &&
        user.displayName!.isNotEmpty) {
      updates['name'] = user.displayName;
    }
    if (data['auth_provider'] == null) {
      updates['auth_provider'] = 'google';
    }
    if (data['created_at'] == null && data['createdAt'] != null) {
      updates['created_at'] = data['createdAt'];
    }

    if (updates.isNotEmpty) {
      await userRef.update(updates);
    }
  }

  /// 🚀 Navigate Based on Role
  Future<void> _handleUserNavigation(User user) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    String role = userDoc['role'];

    if (!mounted) return;

    try {
      await NotificationService.instance.initialize();
    } catch (_) {}

    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orangeColor = Colors.orange;

    return Scaffold(
      backgroundColor: Colors.white24,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Gulf Limousine Travel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 40),

                  /// EMAIL
                  TextField(
                    controller: _emailController,
                    decoration: _inputDecoration("Email", Icons.email),
                  ),
                  const SizedBox(height: 16),

                  /// PASSWORD
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: _inputDecoration("Password", Icons.lock),
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const ForgotPasswordDialog(),
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// EMAIL LOGIN BUTTON
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeColor,
                      padding:
                      const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                    ),
                    onPressed:
                    _isLoading ? null : () => _login(context),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// GOOGLE LOGIN BUTTON
                  OutlinedButton.icon(
                    icon:
                    const Icon(Icons.login, color: Colors.orange),
                    label: const Text(
                      "Continue with Google",
                      style:
                      TextStyle(color: Colors.orange),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Colors.orange),
                      padding:
                      const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : _loginWithGoogle,
                  ),

                  const SizedBox(height: 20),

                  /// SIGN UP
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      const Text(
                          "Don't have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const SignUpDialog(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon:
      Icon(icon, color: Colors.orange),
      enabledBorder: OutlineInputBorder(
        borderSide:
        const BorderSide(color: Colors.orange),
        borderRadius:
        BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(
            color: Colors.orange, width: 2),
        borderRadius:
        BorderRadius.circular(12),
      ),
    );
  }
}
