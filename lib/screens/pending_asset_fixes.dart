import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PendingAssetFixesScreen extends StatefulWidget {
  @override
  _PendingAssetFixesScreenState createState() =>
      _PendingAssetFixesScreenState();
}

class _PendingAssetFixesScreenState extends State<PendingAssetFixesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ใช้ MediaQuery เพื่อดึงข้อมูลขนาดหน้าจอ
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('📋 ครุภัณฑ์ที่รอการแก้ไข'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ช่องค้นหา
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.03), // ปรับขนาด padding
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: '🔍 ค้นหาครุภัณฑ์...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream:
                  _firestore
                      .collection('asset_issues')
                      .where('status', isEqualTo: 'approved')
                      .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var issues =
                    snapshot.data!.docs.where((issue) {
                      String assetNumber = issue['asset_number'].toLowerCase();
                      String description = issue['description'].toLowerCase();
                      return assetNumber.contains(searchQuery) ||
                          description.contains(searchQuery);
                    }).toList();

                if (issues.isEmpty) {
                  return const Center(
                    child: Text(
                      '🚫 ไม่มีครุภัณฑ์ที่รอการแก้ไข',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: issues.length,
                  itemBuilder: (context, index) {
                    var issue = issues[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: screenHeight * 0.01,
                      ),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.build_circle,
                            color: Colors.orange,
                            size: 36,
                          ),
                          title: Text(
                            "ครุภัณฑ์: ${issue['asset_number']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "📝 รายละเอียด: ${issue['description']}",
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AssetFixDetailScreen(
                                      assetNumber: issue['asset_number'],
                                      description: issue['description'],
                                      issueId: issue.id,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AssetFixDetailScreen extends StatefulWidget {
  final String assetNumber;
  final String description;
  final String issueId;

  const AssetFixDetailScreen({
    required this.assetNumber,
    required this.description,
    required this.issueId,
  });

  @override
  _AssetFixDetailScreenState createState() => _AssetFixDetailScreenState();
}

class _AssetFixDetailScreenState extends State<AssetFixDetailScreen> {
  final TextEditingController reasonController = TextEditingController();

  Future<void> _updateAssetCondition(String status) async {
    try {
      // บันทึกข้อมูลใน collection 'resolved_asset_fixes'
      await FirebaseFirestore.instance.collection('resolved_asset_fixes').add({
        'asset_number': widget.assetNumber,
        'issue_id': widget.issueId,
        'status': status,
        'reason': reasonController.text,
        'resolved_at': FieldValue.serverTimestamp(),
      });

      // อัปเดตสถานะของปัญหาครุภัณฑ์ใน collection 'asset_issues'
      await FirebaseFirestore.instance
          .collection('asset_issues')
          .doc(widget.issueId)
          .update({'status': 'resolved'});

      // ถ้าสถานะเป็น 'fixed' ให้แก้ไข condition ของครุภัณฑ์ใน collection 'assets'
      if (status == 'fixed') {
        QuerySnapshot assetQuery =
            await FirebaseFirestore.instance
                .collection("assets")
                .where("asset_id", isEqualTo: widget.assetNumber)
                .get();

        if (assetQuery.docs.isNotEmpty) {
          for (var doc in assetQuery.docs) {
            await doc.reference.update({"condition": "ใช้งานได้ปกติ"});
            print("✅ อัปเดตสินทรัพย์ ${doc.id} เป็น 'ใช้งานได้ปกติ'");
          }
        } else {
          print("⚠️ ไม่พบสินทรัพย์ที่มีหมายเลข: ${widget.assetNumber}");
        }
      }

      // แสดงข้อความยืนยัน
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'fixed' ? '✅ แก้ไขแล้ว' : '❌ ไม่สามารถแก้ไขได้',
          ),
          backgroundColor: status == 'fixed' ? Colors.green : Colors.red,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print("❌ Error updating asset condition: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("🔧 รายละเอียดครุภัณฑ์"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🏷 ครุภัณฑ์: ${widget.assetNumber}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "📌 รายละเอียดปัญหา:",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  widget.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 20),

                // ช่องกรอกเหตุผล
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "📝 กรอกรายละเอียดการแก้ไขที่นี่...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // ปุ่มกด
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _updateAssetCondition('fixed'),
                      icon: const Icon(Icons.check),
                      label: const Text(
                        "แก้ไขแล้ว",
                        style: TextStyle(fontSize: 12), // ลดขนาดของข้อความ
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, // ลดความกว้าง
                          vertical: 8, // ลดความสูง
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _updateAssetCondition('cannot_fix'),
                      icon: const Icon(Icons.close),
                      label: const Text(
                        "ไม่สามารถแก้ไขได้",
                        style: TextStyle(fontSize: 12), // ลดขนาดของข้อความ
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, // ลดความกว้าง
                          vertical: 8, // ลดความสูง
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
    );
  }
}
