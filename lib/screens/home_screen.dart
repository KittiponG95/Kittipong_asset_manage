import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'asset_list_screen.dart';
import 'add_asset_screen.dart';
import 'dashboard_screen.dart';
import 'report_issue_screen.dart';
import 'report_list_screen.dart';
import 'user_report_list_screen.dart';
import 'admin_approved_reports_screen.dart';
import 'scan_qr_code_screen.dart';
import 'admin_user_management.dart';
import 'user_profile_screen.dart';
import 'generate_qr_code_screen.dart'; // นำเข้าไฟล์ GenerateQrCodeScreen
import 'search_asset_screen.dart';
import 'admin_rejected_reports_screen.dart';
import 'pending_asset_fixes.dart';
import 'resolved_asset_fixes_Screen.dart';
import 'damaged_assets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String userName = "กำลังโหลด...";
  String userEmail = "กำลังโหลด...";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email ?? "ไม่พบอีเมล";
      });

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'] ?? "ไม่พบชื่อ";
        });
      }
    }
  }

  Future<String> _fetchUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc['role'] != null) {
        return userDoc['role'];
      }
    }
    return "user";
  }

  Future<void> _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _fetchUserRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        String role = snapshot.data ?? "user";

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text("HOME"),
            backgroundColor: Colors.blueAccent,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          drawer: _buildDrawer(role),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: _buildMenuItems(role),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(String role) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(userEmail),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Colors.blueAccent),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("โปรไฟล์ของฉัน"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text(
              "ออกจากระบบ",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _logout(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(String role) {
    List<Widget> menuItems = [];

    // เมนูอื่นๆ สำหรับทุกคน
    menuItems.add(
      _buildMenuItem(
        Icons.search,
        "ค้นหาครุภัณฑ์",
        Colors.indigo,
        () => _navigateTo(const SearchAssetScreen()),
      ),
    );

    // เพิ่มปุ่มสำหรับติดตามสถานะการแก้ไขครุภัณฑ์

    if (role == "admin" || role == "staff") {
      menuItems.add(
        _buildMenuItem(
          Icons.qr_code_scanner,
          "สแกน QR",
          Colors.blue,
          () => _navigateTo(ScanQrCodeScreen()),
        ),
      );
      menuItems.add(
        _buildMenuItem(
          Icons.add_box,
          "เพิ่มครุภัณฑ์",
          Colors.grey,
          () => _navigateTo(AddAssetScreen()),
        ),
      );
      menuItems.add(
        _buildMenuItem(
          Icons.list,
          "รายการครุภัณฑ์",
          Colors.grey,
          () => _navigateTo(AssetListScreen()),
        ),
      );

      menuItems.add(
        _buildMenuItem(
          Icons.qr_code,
          "Generate QR Code",
          Colors.blue,
          () => _navigateTo(SelectAssetForQrCodeScreen()),
        ),
      );
      menuItems.add(
        _buildMenuItem(
          Icons.report_problem,
          "แจ้งปัญหา",
          Colors.red,
          () => _navigateTo(ReportIssueScreen()),
        ),
      );
      menuItems.add(
        _buildMenuItem(
          Icons.check_circle,
          "รายงานที่อนุมัติ",
          Colors.green,
          () => _navigateTo(AdminApprovedReportsScreen()),
        ),
      );
      menuItems.add(
        _buildMenuItem(
          Icons.cancel,
          "รายงานที่ไม่ได้รับการอนุมัติ",
          Colors.redAccent,
          () => _navigateTo(AdminRejectedReportsScreen()),
        ),
      );
      menuItems.add(
        _buildMenuItem(
          Icons.list, // เปลี่ยนไอคอนที่ต้องการ เช่น report_problem
          "รายการครุภัณฑ์ที่ชำรุด",
          Colors.red, // เปลี่ยนสีเป็นสีที่ต้องการ เช่น สีแดง
          () => _navigateTo(DamagedAssetsScreen()),
        ),
      );

      if (role == "admin") {
        menuItems.add(
          _buildMenuItem(
            Icons.admin_panel_settings,
            "จัดการผู้ใช้",
            Colors.purple,
            () => _navigateTo(AdminUserManagementScreen()),
          ),
        );
      }
      menuItems.add(
        _buildMenuItem(
          Icons.list,
          "รายงานการแจ้งปัญหา",
          Colors.blue,
          () => _navigateTo(ReportListScreen()),
        ),
      );
      menuItems.add(
        _buildMenuItem(
          Icons.build,
          "รายการแก้ไขครุภัณฑ์ที่ชำรุด",
          Colors.orange,
          () => _navigateTo(FixedAssetsScreen()),
        ),
      );
      menuItems.add(
        _buildMenuItem(
          Icons.build,
          "รอซ่อมครุภัณฑ์",
          Colors.deepOrange,
          () => _navigateTo(PendingAssetFixesScreen()),
        ),
      );
      menuItems.add(
        _buildMenuItem(
          Icons.dashboard,
          "Dashboard",
          Colors.blue,
          () => _navigateTo(DashboardScreen()),
        ),
      );
    } else if (role == "user") {
      menuItems.add(
        _buildMenuItem(
          Icons.qr_code_scanner,
          "สแกน QR",
          Colors.blue,
          () => _navigateTo(ScanQrCodeScreen()),
        ),
      );
      menuItems.add(
        _buildMenuItem(
          Icons.report_problem,
          "แจ้งปัญหา",
          Colors.blue,
          () => _navigateTo(ReportIssueScreen()),
        ),
      );
    }

    // ปุ่ม "รายงานของฉัน"
    menuItems.add(
      _buildMenuItem(
        Icons.history,
        "รายงานของฉัน",
        Colors.teal,
        () => _navigateTo(
          UserReportListScreen(currentUserId: _auth.currentUser?.uid ?? ""),
        ),
      ),
    );

    return menuItems;
  }

  Widget _buildMenuItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color.withOpacity(1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}
