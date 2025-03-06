import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _login() async {
    try {
      // ล็อกอินด้วย email & password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      User? user = userCredential.user;
      if (user != null && !user.emailVerified) {
        // หากอีเมลยังไม่ได้ยืนยัน ให้แจ้งเตือนและออกจากระบบ
        await _showDialog(
          "Email ไม่ได้รับการยืนยัน",
          "โปรดตรวจสอบอีเมลของคุณเพื่อยืนยันบัญชี แล้วลองเข้าสู่ระบบอีกครั้ง",
        );
        await _auth.signOut();
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      _showDialog("เข้าสู่ระบบล้มเหลว", "$e");
    }
  }

  Future<void> resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showDialog("ข้อผิดพลาด", "โปรดกรอกอีเมลก่อนกู้รหัสผ่าน");
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      _showDialog("สำเร็จ", "ส่งลิงก์รีเซ็ตรหัสผ่านไปที่อีเมลของคุณแล้ว");
    } catch (e) {
      _showDialog("เกิดข้อผิดพลาด", "$e");
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _showDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ตกลง"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เข้าสู่ระบบ")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email),
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _login,
                  icon: const Icon(Icons.login),
                  label: const Text("เข้าสู่ระบบ"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TextButton(
                    onPressed: resetPassword,
                    child: const Text(
                      "ลืมรหัสผ่าน?",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text(
                  "ยังไม่มีบัญชี? สมัครสมาชิก",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
