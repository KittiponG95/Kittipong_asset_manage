import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'report_detail_screen.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  _ReportListScreenState createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = ""; // กำหนดค่าค้นหาเริ่มต้นเป็นค่าว่าง

  // ฟังก์ชั่นสำหรับดึงข้อมูลจาก Firestore
  Future<List<Map<String, dynamic>>> _fetchReports() async {
    try {
      Query query = FirebaseFirestore.instance.collection("asset_issues");

      // กรองข้อมูลที่สถานะเป็น "waiting" เท่านั้น
      query = query.where("status", isEqualTo: "waiting");

      // ถ้ามีการกรอกคำค้นหาให้ทำการค้นหาตาม asset_number
      if (_searchQuery.isNotEmpty) {
        query = query.where("asset_number", isEqualTo: _searchQuery);
      }

      final querySnapshot = await query.get();

      List<Map<String, dynamic>> reports = [];
      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        reports.add({
          "id": doc.id,
          "title": data["description"] ?? "ไม่มีรายละเอียด",
          "description": data["description"] ?? "ไม่มีรายละเอียด",
          "assetNumber": data["asset_number"] ?? "ไม่ทราบหมายเลข",
          "status": data.containsKey("status") ? data["status"] : "waiting",
          "created_at": data["created_at"], // เพิ่มดึงข้อมูล created_at
        });
      }
      return reports;
    } catch (e) {
      print("Error fetching reports: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รายการแจ้งปัญหา"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text; // กำหนดค่าการค้นหา
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'ค้นหาหมายเลขครุภัณฑ์',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              // เรียกใช้ฟังก์ชัน _fetchReports เพื่อดึงข้อมูล
              future: _fetchReports(),
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
                  return const Center(child: Text("ไม่มีข้อมูล"));
                }

                final reports = snapshot.data!;

                return ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];

                    // แปลง created_at เป็น DateTime และ format วันที่
                    Timestamp? createdAt = report["created_at"];
                    String createdAtFormatted =
                        createdAt != null
                            ? DateFormat(
                              'dd MMM yyyy, HH:mm',
                            ).format(createdAt.toDate())
                            : 'ไม่ระบุวันที่';

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(report["title"]),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("หมายเลขครุภัณฑ์: ${report["assetNumber"]}"),
                            Text("วันที่สร้าง: $createdAtFormatted"),
                          ],
                        ),
                        trailing: Icon(
                          report["status"] == "waiting"
                              ? Icons.hourglass_empty
                              : report["status"] == "approved"
                              ? Icons.check_circle
                              : Icons.cancel,
                          color:
                              report["status"] == "waiting"
                                  ? Colors.orange
                                  : report["status"] == "approved"
                                  ? Colors.green
                                  : Colors.red,
                        ),
                        onTap: () {
                          // ไปที่ Report Detail และส่งข้อมูลไป
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      ReportDetailScreen(report: report),
                            ),
                          );
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
    );
  }
}
