import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // ✅ นำเข้า intl

class AdminRejectedReportsScreen extends StatelessWidget {
  const AdminRejectedReportsScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchRejectedReports() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection("asset_issues")
              .where("status", whereIn: ["rejected", "waiting"])
              .get();

      List<Map<String, dynamic>> reports =
          querySnapshot.docs.map((doc) {
            var data = doc.data();
            Timestamp? rejectedAt = data["rejectedAt"] as Timestamp?;

            return {
              "id": doc.id,
              "title": data["asset_number"] ?? "ไม่มีหมายเลขครุภัณฑ์",
              "description": data["description"] ?? "ไม่มีรายละเอียด",
              "assetNumber":
                  data["asset_number"]?.toString() ?? "ไม่ทราบหมายเลข",
              "status": data["status"] ?? "waiting",
              "imageUrl": data["image_url"] ?? "",
              "approvedBy": data["approvedBy"] ?? "ไม่ทราบผู้อนุมัติ",
              "rejectedBy": data["rejectedBy"] ?? "ไม่ทราบผู้ปฏิเสธ",
              "rejectedAt": rejectedAt?.toDate(),
              "rejectionReason":
                  data["rejectionReason"]?.toString() ?? "ไม่มีเหตุผล",
            };
          }).toList();

      reports.sort(
        (a, b) => (b["rejectedAt"]?.millisecondsSinceEpoch ?? 0).compareTo(
          a["rejectedAt"]?.millisecondsSinceEpoch ?? 0,
        ),
      );

      return reports;
    } catch (e) {
      print("Error fetching reports: $e");
      return [];
    }
  }

  Future<void> _deleteReport(String reportId) async {
    try {
      await FirebaseFirestore.instance
          .collection("asset_issues")
          .doc(reportId)
          .delete();
      print("Report deleted successfully");
    } catch (e) {
      print("Error deleting report: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("คำร้องที่ไม่ได้อนุมัติ")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchRejectedReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("ไม่มีคำร้องที่ไม่ได้อนุมัติ"));
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
                            Icons.report,
                            size: 50,
                            color: Colors.red,
                          ),
                  title: Text(
                    report["title"],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "ไม่อนุมัติโดย: ${report["rejectedBy"]}\n"
                    "ปฏิเสธเมื่อ: ${_formatTimestamp(report["rejectedAt"])}",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      bool? confirmDelete = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text("ยืนยันการลบ"),
                              content: const Text(
                                "คุณต้องการลบคำร้องนี้หรือไม่?",
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: const Text("ยกเลิก"),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  child: const Text("ยืนยัน"),
                                ),
                              ],
                            ),
                      );

                      if (confirmDelete == true) {
                        await _deleteReport(report["id"]);
                      }
                    },
                  ),
                  onTap: () {
                    // Navigate to the detail screen when the list item is tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                RejectedReportDetailScreen(report: report),
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

class RejectedReportDetailScreen extends StatelessWidget {
  final Map<String, dynamic> report;

  const RejectedReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    String rejectedDateText = "ไม่ทราบวันที่";
    if (report["rejectedAt"] != null) {
      rejectedDateText = DateFormat(
        "dd/MM/yyyy HH:mm",
      ).format(report["rejectedAt"]); // ✅ ใช้ DateFormat
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("รายละเอียดคำร้อง"),
        backgroundColor: Colors.redAccent,
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
                      report["assetNumber"],
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.description,
                      "รายละเอียด",
                      report["description"],
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.info_outline,
                      "สถานะ",
                      report["status"] == "rejected"
                          ? "ถูกปฏิเสธ"
                          : "รออนุมัติ",
                      color:
                          report["status"] == "rejected"
                              ? Colors.red
                              : Colors.orange,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.person_off,
                      "ผู้ปฏิเสธ",
                      report["rejectedBy"],
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.calendar_today,
                      "วันที่ถูกปฏิเสธ",
                      rejectedDateText,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.report_problem,
                      "เหตุผลการปฏิเสธ",
                      report["rejectionReason"],
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
          child: Text(value, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
