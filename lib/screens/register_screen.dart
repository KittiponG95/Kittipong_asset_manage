import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController(); // Confirm Password controller
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });

    // Check if the password and confirm password are the same
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("รหัสผ่านและยืนยันรหัสผ่านไม่ตรงกัน")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Create new user with email and password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Set the user's role as "user" in Firestore (default)
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': userCredential.user!.email,
        'role': 'user', // Default role is "user"
        'name': 'xxx',
        'phone': 'xxx',
        'suspendReason': null,
        'suspended': false,
        // You can later add a name field to collect data
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send verification email to the user
      User? user = userCredential.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification(); // Send verification email
      }

      // Show notification or dialog for success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("สมัครสมาชิกสำเร็จ! โปรดตรวจสอบอีเมลเพื่อยืนยัน"),
        ),
      );

      // Navigate to login screen
      Navigator.pop(context); // Go back to login page
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("สมัครสมาชิก")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Email"),
            TextField(controller: _emailController),
            const SizedBox(height: 10),
            const Text("Password"),
            TextField(controller: _passwordController, obscureText: true),
            const SizedBox(height: 10),
            const Text("Confirm Password"),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
            ), // Confirm Password field
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text("สมัครสมาชิก"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
