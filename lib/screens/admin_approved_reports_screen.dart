import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminApprovedReportsScreen extends StatelessWidget {
  const AdminApprovedReportsScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchApprovedReports() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection("asset_issues")
              .where("status", isEqualTo: "approved")
              .get();

      return querySnapshot.docs.map((doc) {
        var data = doc.data();
        Timestamp? approvedAt = data["approvedAt"] as Timestamp?;
        return {
          "id": doc.id,
          "title": data["asset_number"] ?? "ไม่มีรหัสครุภัณฑ์",
          "description": data["description"] ?? "ไม่มีรายละเอียด",
          "asset_number": data["asset_number"]?.toString() ?? "ไม่ทราบหมายเลข",
          "status": data["status"] ?? "approved",
          "imageUrl": data["imageUrl"] ?? "",
          "approvedBy": data["approvedBy"] ?? "ไม่ทราบผู้อนุมัติ",
          "approvedReason": data["approvedReason"] ?? "ไม่ระบุเหตุผล",
          "approvedAt": approvedAt?.toDate(),
        };
      }).toList();
    } catch (e) {
      debugPrint("Error fetching approved reports: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("คำร้องที่อนุมัติแล้ว")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchApprovedReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("ไม่มีคำร้องที่อนุมัติ"));
          }

          final reports = snapshot.data!;

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading:
                      report["imageUrl"].isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              report["imageUrl"],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                  ),
                            ),
                          )
                          : const Icon(
                            Icons.check_circle,
                            size: 50,
                            color: Colors.green,
                          ),
                  title: Text(
                    report["title"],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "อนุมัติโดย: ${report["approvedBy"]}\n"
                    "อนุมัติเมื่อ: ${_formatTimestamp(report["approvedAt"])}", // ✅ ใช้ฟังก์ชันจัดรูปแบบ
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ApprovedReportDetailScreen(report: report),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return "ไม่ระบุเวลา";
    return DateFormat("dd/MM/yyyy HH:mm").format(dateTime);
  }
}

class ApprovedReportDetailScreen extends StatelessWidget {
  final Map<String, dynamic> report;

  const ApprovedReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    String rejectedDateText = "ไม่ทราบวันที่";
    if (report["approvedAt"] != null) {
      rejectedDateText = DateFormat(
        "dd/MM/yyyy HH:mm",
      ).format(report["approvedAt"]);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("รายละเอียดคำร้อง"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report["imageUrl"].isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  report["imageUrl"],
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported,
                        size: 100,
                        color: Colors.grey,
                      ),
                ),
              ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      Icons.numbers,
                      "หมายเลขครุภัณฑ์",
                      report["asset_number"],
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.description,
                      "รายละเอียด",
                      report["description"],
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.check_circle,
                      "สถานะ",
                      "อนุมัติแล้ว",
                      color: Colors.green,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.person,
                      "ผู้อนุมัติ",
                      report["approvedBy"],
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.comment,
                      "เหตุผลในการอนุมัติ",
                      report["approvedReason"],
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.calendar_today,
                      "วันที่ถูกปฏิเสธ",
                      rejectedDateText,
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

  Widget _buildDetailRow(
    IconData icon,
    String title,
    String value, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: color ?? Colors.black87),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
