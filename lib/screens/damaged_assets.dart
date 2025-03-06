import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DamagedAssetsScreen extends StatelessWidget {
  const DamagedAssetsScreen({super.key});

  // ฟังก์ชันดึงรายการครุภัณฑ์ที่ชำรุด
  Future<List<Map<String, dynamic>>> _fetchDamagedAssets() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('assets') // แก้เป็นชื่อคอลเลกชันของคุณ
              .where("condition", isEqualTo: "ชำรุด")
              .get();

      List<Map<String, dynamic>> assets = [];
      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        assets.add({
          "id": doc.id,
          "name": data["name"] ?? "ไม่มีชื่อ",
          "asset_id": data["asset_id"] ?? "ไม่ทราบหมายเลข",
          "condition": data["condition"] ?? "ไม่ระบุ",
          "imageUrl": data["image_url"] ?? "",
        });
      }
      return assets;
    } catch (e) {
      print("Error fetching assets: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รายการครุภัณฑ์ชำรุด"),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchDamagedAssets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("ไม่มีครุภัณฑ์ที่ชำรุด"));
          }

          final assets = snapshot.data!;

          return ListView.builder(
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    asset["name"],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("หมายเลขครุภัณฑ์: ${asset["asset_id"]}"),
                  trailing: Text(
                    asset["condition"],
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  leading:
                      asset["imageUrl"].isNotEmpty
                          ? Image.network(
                            asset["imageUrl"],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                          : const Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                  onTap: () {
                    _showAssetDetails(context, asset);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ฟังก์ชันแสดงรายละเอียดของครุภัณฑ์
  void _showAssetDetails(BuildContext context, Map<String, dynamic> asset) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(asset["name"]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              asset["imageUrl"].isNotEmpty
                  ? Image.network(asset["imageUrl"], height: 150)
                  : const Icon(
                    Icons.broken_image,
                    size: 100,
                    color: Colors.grey,
                  ),
              const SizedBox(height: 10),
              Text("หมายเลขครุภัณฑ์: ${asset["asset_id"]}"),
              Text("สถานะ: ${asset["condition"]}"),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("ปิด"),
            ),
          ],
        );
      },
    );
  }
}
