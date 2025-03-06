import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanResultScreen extends StatelessWidget {
  final String qrData;

  const ScanResultScreen({super.key, required this.qrData});

  // ฟังก์ชั่นดึงข้อมูลจาก Firestore
  Future<Map<String, dynamic>?> _fetchAssetDetails() async {
    try {
      final assetDoc =
          await FirebaseFirestore.instance
              .collection('assets')
              .where('asset_id', isEqualTo: qrData)
              .limit(1)
              .get();

      if (assetDoc.docs.isNotEmpty) {
        return assetDoc.docs.first.data();
      } else {
        return null; // ไม่พบข้อมูล
      }
    } catch (e) {
      print("❌ Error fetching asset details: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ผลลัพธ์จาก QR Code")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchAssetDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("❌ เกิดข้อผิดพลาด: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return _buildNoDataWidget(context);
          }

          final assetData = snapshot.data!;
          return _buildAssetDetails(assetData, context);
        },
      ),
    );
  }

  // 🔹 UI แสดงเมื่อไม่พบข้อมูล
  Widget _buildNoDataWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "❌ ไม่พบข้อมูลครุภัณฑ์",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("🔄 กรอกใหม่"),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 UI แสดงข้อมูลหลังจากสแกน
  Widget _buildAssetDetails(
    Map<String, dynamic> assetData,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "📌 รายละเอียดครุภัณฑ์",
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
                    _buildDetailRow("หมายเลขครุภัณฑ์", assetData['asset_id']),
                    _buildDetailRow("ชื่อครุภัณฑ์", assetData['name']),
                    _buildDetailRow("ปีงบประมาณ", assetData['fiscal_year']),
                    _buildDetailRow("สภาพ", assetData['condition']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("🔄 สแกนใหม่"),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Widget สำหรับแสดงข้อมูลแต่ละแถว
  Widget _buildDetailRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$title:",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            value ?? "N/A", // ถ้าไม่มีข้อมูลให้แสดง N/A
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
