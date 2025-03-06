import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'asset_detail_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  _AssetListScreenState createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = ""; // กำหนดค่าค้นหาเริ่มต้นเป็นค่าว่าง

  Future<void> _deleteAsset(String assetId) async {
    // ยืนยันการลบ
    bool confirmDelete = await _showDeleteConfirmationDialog();
    if (confirmDelete) {
      try {
        // ลบเอกสารจาก Firestore
        await FirebaseFirestore.instance
            .collection("assets")
            .doc(assetId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ลบครุภัณฑ์เรียบร้อยแล้ว")),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("ไม่สามารถลบครุภัณฑ์ได้: $e")));
      }
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("ยืนยันการลบ"),
          content: const Text("คุณแน่ใจหรือไม่ที่จะลบครุภัณฑ์นี้?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("ยกเลิก"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("ยืนยัน"),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  Future<void> _scanQRCode() async {
    // ฟังก์ชันเปิดหน้าสแกน QR Code
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result != null) {
      setState(() {
        _searchController.text = result; // แสดงผลการสแกนในช่องค้นหา
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รายการครุภัณฑ์"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _searchQuery =
                    _searchController.text.trim(); // กำหนดค่าการค้นหา
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanQRCode, // เปิดหน้าสแกน QR Code
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection("assets")
                .where("asset_id", isGreaterThanOrEqualTo: _searchQuery)
                .where("asset_id", isLessThan: _searchQuery + 'z')
                .orderBy("created_at", descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("ไม่มีข้อมูลครุภัณฑ์"));
          }

          final assets = snapshot.data!.docs;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'ค้นหาครุภัณฑ์',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final asset = assets[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                      shadowColor: Colors.green.shade200,
                      child: ListTile(
                        leading: const Icon(
                          Icons.business,
                          color: Colors.green,
                        ),
                        title: Text(
                          asset["asset_id"] ?? "ไม่ระบุรหัสครุภัณฑ์",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          "ชื่อครุภัณฑ์: ${asset["name"] ?? "ไม่ระบุชื่อ"}\nแบรนด์: ${asset["brand"]}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteAsset(assets[index].id);
                              },
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 18),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AssetDetailScreen(
                                    assetId: assets[index].id,
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// หน้าแสกน QR Code
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("สแกน QR Code"),
        backgroundColor: Colors.green,
      ),
      body: MobileScanner(
        controller: _scannerController,
        onDetect: (barcodeCapture) {
          if (_isScanning) return;

          setState(() {
            _isScanning = true;
          });

          final List<Barcode> barcodes = barcodeCapture.barcodes;

          if (barcodes.isNotEmpty) {
            final Barcode barcode = barcodes.first;
            final String scannedData = barcode.displayValue ?? '';

            if (scannedData.isNotEmpty) {
              Navigator.pop(context, scannedData); // ส่งค่ากลับไป
            }
          }
        },
      ),
    );
  }
}
