import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditUserScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const EditUserScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<EditUserScreen> createState() =>
      _EditUserScreenState();
}

class _EditUserScreenState
    extends State<EditUserScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController roleController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.userData['name']);
    emailController =
        TextEditingController(text: widget.userData['email']);
    roleController =
        TextEditingController(text: widget.userData['role']);
    phoneController = TextEditingController(
        text: widget.userData['phone_number']);
  }

  Future<void> updateUser() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'name': nameController.text,
      'email': emailController.text,
      'role': roleController.text,
      'phone_number': phoneController.text,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Edit User"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildField(nameController, "Name"),
            buildField(emailController, "Email"),
            buildField(phoneController, "Phone Number"),
            buildField(roleController, "Role"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateUser,
              child: const Text("Update User"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(
      TextEditingController controller,
      String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        style:
        const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
          const TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide:
            BorderSide(color: Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}
