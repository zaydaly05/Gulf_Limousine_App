import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase_options.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();

  String role = "user";
  bool _isLoading = false;

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    FirebaseApp? secondaryApp;

    try {
      setState(() => _isLoading = true);

      // Use a secondary Auth instance so the admin stays signed in.
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryAuth_${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final UserCredential credential =
          await secondaryAuth.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: "123456", // default password
      );

      final uid = credential.user!.uid;
      final secondaryFirestore =
          FirebaseFirestore.instanceFor(app: secondaryApp);

      // Write as the new user so Firestore rules allow self-profile creation.
      await secondaryFirestore.collection('users').doc(uid).set({
        'name': name.text.trim(),
        'email': email.text.trim(),
        'phone': phone.text.trim(),
        'phone_number': phone.text.trim(),
        'role': role,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User created successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Failed to create user"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (secondaryApp != null) {
        await FirebaseAuth.instanceFor(app: secondaryApp).signOut();
        await secondaryApp.delete();
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Add User"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _input("Full Name", name),
              _input("Email", email,
                  type: TextInputType.emailAddress),
              _input("Phone Number", phone,
                  type: TextInputType.phone),

              const SizedBox(height: 10),

              const Text(
                "User Role",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 5),

              DropdownButtonFormField<String>(
                initialValue: role,
                dropdownColor: Colors.grey.shade900,
                items: ["user", "admin"]
                    .map(
                      (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                    .toList(),
                onChanged: (val) =>
                    setState(() => role = val!),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade800,
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: _isLoading ? null : _createUser,
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text("Create User"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
      String label,
      TextEditingController controller, {
        TextInputType type = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: (v) =>
        v == null || v.isEmpty ? "Required" : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
          const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.grey.shade800,
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(10),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide:
            BorderSide(color: Colors.orange),
          ),
        ),
      ),
    );
  }
}
