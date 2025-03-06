import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth
import 'package:mobile_scanner/mobile_scanner.dart'; // เพิ่มการใช้งาน mobile_scanner

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  _ReportIssueScreenState createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final TextEditingController _assetNumberController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // ฟังก์ชั่นตรวจสอบและส่งรายงาน
  void _submitReport() async {
    String assetNumber = _assetNumberController.text;
    String description = _descriptionController.text;

    User? user = FirebaseAuth.instance.currentUser;
    String? userEmail = user?.email ?? "ไม่ระบุอีเมล";

    final assetDoc =
        await FirebaseFirestore.instance
            .collection("assets")
            .where("asset_id", isEqualTo: assetNumber)
            .limit(1)
            .get();

    if (assetDoc.docs.isNotEmpty) {
      FirebaseFirestore.instance.collection("asset_issues").add({
        "asset_number": assetNumber,
        "description": description,
        "status": "waiting",
        "created_at": FieldValue.serverTimestamp(),
        "user_email": userEmail,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ส่งรายงานปัญหาเรียบร้อยแล้ว")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไม่พบหมายเลขครุภัณฑ์ในระบบ")),
      );
    }
  }

  // ฟังก์ชั่นสแกน QR Code
  void _scanQRCode() async {
    final scannedData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (scannedData != null && scannedData.isNotEmpty) {
      setState(() {
        _assetNumberController.text =
            scannedData; // กรอกหมายเลขที่สแกนลงในฟิลด์
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("แจ้งปัญหาครุภัณฑ์")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _assetNumberController,
              decoration: InputDecoration(
                labelText: "หมายเลขครุภัณฑ์",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanQRCode, // เรียกฟังก์ชั่นสแกน QR Code
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "รายละเอียดปัญหา",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitReport,
              child: const Text("ส่งแจ้งปัญหา"),
            ),
          ],
        ),
      ),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = false; // ใช้ตัวแปรนี้เพื่อป้องกันการแสกนซ้ำ

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
          if (_isScanning) return; // ป้องกันการแสกนซ้ำ

          setState(() {
            _isScanning = true; // เริ่มต้นการแสกน
          });

          final List<Barcode> barcodes = barcodeCapture.barcodes;

          if (barcodes.isNotEmpty) {
            final Barcode barcode = barcodes.first;
            final String scannedData = barcode.displayValue ?? '';

            if (scannedData.isNotEmpty) {
              Navigator.pop(context, scannedData); // ส่งค่ากลับไป
            } else {
              Navigator.pop(context); // หากไม่ได้ข้อมูลอะไรกลับมา
            }
          }
        },
      ),
    );
  }
}
