import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  _ReportDetailScreenState createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final TextEditingController reasonController = TextEditingController();

  // 🔹 ฟังก์ชันดึงชื่อของผู้ใช้งานจาก Firestore
  Future<String> _getApproverName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return "ไม่ทราบชื่อ";

    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData["name"] ?? "ไม่ทราบชื่อ";
      }
    } catch (e) {
      debugPrint("❌ เกิดข้อผิดพลาดในการดึงข้อมูลผู้ใช้: $e");
    }

    return "ไม่ทราบชื่อ"; // ถ้าเกิดข้อผิดพลาด
  }

  // 🔹 ฟังก์ชันอัปเดตสถานะของรายงาน
  Future<void> _updateStatus(BuildContext context, String status) async {
    String reason = reasonController.text.trim();

    if (reason.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("กรุณากรอกเหตุผลก่อนที่จะอนุมัติหรือไม่อนุมัติ"),
          ),
        );
      }
      return;
    }

    try {
      String approver = await _getApproverName();
      Timestamp now = Timestamp.now();

      // ✅ อัปเดตสถานะใน Firestore
      await FirebaseFirestore.instance
          .collection("asset_issues")
          .doc(widget.report["id"])
          .update({
            "status": status,
            if (status == "approved") "approvedReason": reason,
            if (status == "rejected") "rejectionReason": reason,
            if (status == "approved") "approvedBy": approver,
            if (status == "rejected") "rejectedBy": approver,
            if (status == "approved") "approvedAt": now,
            if (status == "rejected") "rejectedAt": now,
          });

      // ✅ อัปเดตสถานะของสินทรัพย์
      if (status == "approved") {
        String assetNumber = widget.report["assetNumber"];

        QuerySnapshot assetQuery =
            await FirebaseFirestore.instance
                .collection("assets")
                .where("asset_id", isEqualTo: assetNumber)
                .get();

        if (assetQuery.docs.isNotEmpty) {
          for (var doc in assetQuery.docs) {
            await doc.reference.update({"condition": "ชำรุด"});
            debugPrint("✅ อัปเดตสินทรัพย์ ${doc.id} เป็น 'ชำรุด'");

            // 🔹 ดึงข้อมูลมาเช็ค
            DocumentSnapshot updatedDoc = await doc.reference.get();
            debugPrint("🔄 Condition ล่าสุด: ${updatedDoc["condition"]}");
          }
        } else {
          debugPrint("⚠️ ไม่พบสินทรัพย์ที่มีหมายเลข: $assetNumber");
        }
      }

      // ✅ ตรวจสอบว่า widget ยัง active อยู่ก่อนแสดง SnackBar หรือปิดหน้า
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("สถานะอัปเดตเป็น $status")));

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Timestamp? createdAt = widget.report["created_at"];
    String createdAtFormatted =
        createdAt != null
            ? DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toDate())
            : 'ไม่ระบุวันที่';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.report["title"]),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "รายละเอียดปัญหา:",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.report["description"] ?? "ไม่มีรายละเอียด"),
                    const SizedBox(height: 16),
                    Text(
                      "หมายเลขครุภัณฑ์: ${widget.report["assetNumber"]}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "สถานะ: ${widget.report["status"]}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            widget.report["status"] == "waiting"
                                ? Colors.orange
                                : widget.report["status"] == "approved"
                                ? Colors.green
                                : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "วันที่สร้าง: $createdAtFormatted",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "เหตุผล",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: "กรอกเหตุผลที่นี่",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _updateStatus(context, "approved");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("อนุมัติ"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _updateStatus(context, "rejected");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("ไม่อนุมัติ"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
