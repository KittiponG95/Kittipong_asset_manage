import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  _AdminUserManagementScreenState createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    currentUser = _auth.currentUser;
  }

  // ตรวจสอบสิทธิ์ Admin
  Future<void> _checkAdminAccess() async {
    if (currentUser != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(currentUser!.uid).get();
      if (doc.exists && doc['role'] != 'admin') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("คุณไม่มีสิทธิ์เข้าถึงหน้านี้")),
        );
        Navigator.pop(context);
      }
    }
  }

  // ลบผู้ใช้
  Future<void> _deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ลบผู้ใช้สำเร็จ")));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    }
  }

  // เปลี่ยนบทบาทผู้ใช้
  Future<void> _changeUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': newRole});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เปลี่ยนบทบาทเป็น $newRole เรียบร้อย")),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    }
  }

  // ระงับบัญชีผู้ใช้
  Future<void> _suspendUser(String uid) async {
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("ระงับการใช้งาน"),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(labelText: "กรุณาใส่เหตุผล"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ยกเลิก"),
            ),
            TextButton(
              onPressed: () async {
                String reason = reasonController.text.trim();
                if (reason.isNotEmpty) {
                  await _firestore.collection('users').doc(uid).update({
                    'suspended': true,
                    'suspendReason': reason,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("บัญชีถูกระงับ: $reason")),
                  );
                  setState(() {});
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("กรุณาใส่เหตุผล")),
                  );
                }
              },
              child: const Text("ยืนยัน"),
            ),
          ],
        );
      },
    );
  }

  // ปลดแบนบัญชี
  Future<void> _unsuspendUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'suspended': false,
        'suspendReason': null,
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("บัญชีถูกปลดแบน")));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("จัดการผู้ใช้"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("ไม่มีข้อมูลผู้ใช้"));
          }

          final users =
              snapshot.data!.docs.where((user) {
                final userData = user.data() as Map<String, dynamic>;
                final role = userData['role'] ?? '';
                final uid = user.id;
                return role != 'admin' && uid != currentUser?.uid;
              }).toList();

          if (users.isEmpty) {
            return const Center(child: Text("ไม่มีผู้ใช้ที่สามารถจัดการได้"));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              var userData = user.data() as Map<String, dynamic>;
              bool isSuspended = userData['suspended'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(userData['email'] ?? "ไม่มีอีเมล"),
                  subtitle: Text(
                    "Role: ${userData['role'] ?? "ไม่ระบุ"}\n"
                    "${isSuspended ? "บัญชีถูกระงับ: ${userData['suspendReason'] ?? ""}" : ""}",
                    style: TextStyle(
                      color: isSuspended ? Colors.red : Colors.black,
                      fontWeight:
                          isSuspended ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(user.id),
                      ),
                      DropdownButton<String>(
                        value:
                            userData['role'], // กำหนดค่า value ให้ตรงกับค่า role ของผู้ใช้
                        items:
                            <String>['user', 'staff']
                                .map<DropdownMenuItem<String>>(
                                  (String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                        onChanged: (String? newValue) async {
                          if (newValue != null &&
                              newValue != userData['role']) {
                            await _changeUserRole(user.id, newValue);
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          isSuspended ? Icons.lock_open : Icons.lock,
                          color: isSuspended ? Colors.green : Colors.orange,
                        ),
                        onPressed: () {
                          isSuspended
                              ? _unsuspendUser(user.id)
                              : _suspendUser(user.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
