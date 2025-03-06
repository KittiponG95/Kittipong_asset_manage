import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'edit_asset_screen.dart';

class AssetDetailScreen extends StatelessWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รายละเอียดครุภัณฑ์"),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection("assets").doc(assetId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("ข้อมูลไม่พบ"));
          }

          final asset = snapshot.data!.data() as Map<String, dynamic>;

          // แปลง timestamp เป็นวันที่
          Timestamp? timestamp = asset["created_at"];
          String createdAtFormatted =
              timestamp != null
                  ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate())
                  : 'ไม่ระบุวันที่';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailCard(
                  "หมายเลขครุภัณฑ์",
                  asset["asset_id"] ?? 'ไม่ระบุ',
                ),
                _buildDetailCard(
                  "ชื่อครุภัณฑ์",
                  asset["name"] ?? 'ไม่ระบุชื่อ',
                ),
                _buildDetailCard("ประเภท", asset["type"] ?? 'ไม่ระบุ'),
                _buildDetailCard(
                  "ราคาซื้อ",
                  "${asset["purchase_price"] ?? 0} บาท",
                ),
                _buildDetailCard("สภาพ", asset["condition"] ?? 'ไม่ระบุ'),
                _buildDetailCard(
                  "สถานที่เก็บ",
                  asset["storage_location"] ?? 'ไม่ระบุ',
                ),
                _buildDetailCard("สถานะ", asset["status"] ?? 'ไม่ระบุ'),
                _buildDetailCard(
                  "วันที่หมดอายุ",
                  asset["expiry_date"] ?? 'ไม่ระบุ',
                ),
                _buildDetailCard(
                  "หมายเลขประกัน",
                  asset["warranty_number"] ?? 'ไม่ระบุ',
                ),
                _buildDetailCard(
                  "ผู้รับผิดชอบ",
                  asset["responsible_person"] ?? 'ไม่ระบุ',
                ),
                _buildDetailCard(
                  "รายละเอียดเพิ่มเติม",
                  asset["additional_notes"] ?? 'ไม่มีรายละเอียด',
                ),
                _buildDetailCard("วันที่สร้าง", createdAtFormatted),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditAssetScreen(assetId: assetId),
                      ),
                    );
                  },
                  child: const Text("แก้ไขข้อมูล"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 24,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Custom Widget to Build Detail Cards
  Widget _buildDetailCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(value, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
