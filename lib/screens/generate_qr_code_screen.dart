import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SelectAssetForQrCodeScreen extends StatefulWidget {
  const SelectAssetForQrCodeScreen({super.key});

  @override
  _SelectAssetForQrCodeScreenState createState() =>
      _SelectAssetForQrCodeScreenState();
}

class _SelectAssetForQrCodeScreenState
    extends State<SelectAssetForQrCodeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedAssetId; // เก็บ asset ที่เลือก
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> allAssets = [];
  List<Map<String, dynamic>> filteredAssets = [];

  // ฟังก์ชันสำหรับดึงข้อมูลครุภัณฑ์จาก Firestore
  Future<List<Map<String, dynamic>>> _fetchAssets() async {
    final querySnapshot =
        await _firestore
            .collection("assets")
            .orderBy(
              "created_at",
              descending: true,
            ) // เรียงลำดับตามวันที่ (ใหม่สุด)
            .get();
    List<Map<String, dynamic>> assets = [];
    for (var doc in querySnapshot.docs) {
      var data = doc.data();
      assets.add({
        "id": doc.id, // Ensure the ID is captured correctly
        "name": data["name"] ?? "ไม่พบชื่อครุภัณฑ์",
        "asset_id": data["asset_id"] ?? "ไม่มีรหัสครุภัณฑ์",
        "condition":
            data["condition"] ?? "ไม่ระบุสภาพ", // เปลี่ยนเป็น condition
        "fiscal_year":
            data["fiscal_year"] ??
            "ไม่ระบุปีงบประมาณ", // เปลี่ยนเป็น fiscal_year
        "created_at": data["created_at"], // เพิ่มข้อมูล created_at
      });
    }
    return assets;
  }

  // ฟังก์ชันสำหรับกรองรายการครุภัณฑ์ตามคำค้น
  void _filterAssets() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredAssets =
          allAssets.where((asset) {
            return asset["name"].toLowerCase().contains(query) ||
                asset["asset_id"].toLowerCase().contains(query);
          }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    // ดึงข้อมูลครุภัณฑ์เมื่อเริ่มต้น
    _fetchAssets().then((assets) {
      setState(() {
        allAssets = assets;
        filteredAssets = assets;
      });
    });

    // ตั้งค่า controller สำหรับการค้นหา
    searchController.addListener(_filterAssets);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("เลือกครุภัณฑ์เพื่อสร้าง QR Code"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'ค้นหาครุภัณฑ์',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchAssets(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("ไม่พบข้อมูลครุภัณฑ์"));
                  }

                  List<Map<String, dynamic>> assets = filteredAssets;

                  return ListView.builder(
                    itemCount: assets.length,
                    itemBuilder: (context, index) {
                      final asset = assets[index];
                      DateTime createdAt =
                          (asset["created_at"] as Timestamp).toDate();

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            asset["asset_id"], // เปลี่ยนเป็น asset_id แสดงตรงนี้
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ชื่อครุภัณฑ์: ${asset["name"] ?? "ไม่ระบุชื่อ"}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "สภาพ: ${asset["condition"] ?? "ไม่ระบุสภาพ"}", // เปลี่ยนเป็น condition
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "ปีงบประมาณ: ${asset["fiscal_year"] ?? "ไม่ระบุปีงบประมาณ"}", // เปลี่ยนเป็น fiscal_year
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "วันที่เพิ่ม: ${createdAt.toLocal().toString().substring(0, 19)}", // แสดงวันที่และเวลา
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.arrow_forward,
                            color: Colors.green,
                          ),
                          onTap: () {
                            setState(() {
                              selectedAssetId = asset["id"];
                            });
                            // เมื่อเลือกแล้วให้ไปที่หน้า generate QR code
                            if (selectedAssetId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => GenerateQrCodeScreen(
                                        assetId:
                                            asset["asset_id"], // ใช้ asset_id ที่เลือก
                                      ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GenerateQrCodeScreen extends StatelessWidget {
  final String assetId;

  const GenerateQrCodeScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate QR Code"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "QR Code for Asset ID",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      QrImageView(
                        data:
                            assetId, // ใช้ asset_id เป็นข้อมูลสำหรับสร้าง QR Code
                        version: QrVersions.auto,
                        size: 250.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Asset ID: $assetId",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // กลับไปหน้าสแกนใหม่
                },
                child: const Text("เลือกใหม่"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
