import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'scan_result_screen.dart';

class ScanQrCodeScreen extends StatefulWidget {
  const ScanQrCodeScreen({super.key});

  @override
  State<ScanQrCodeScreen> createState() => _ScanQrCodeScreenState();
}

class _ScanQrCodeScreenState extends State<ScanQrCodeScreen> {
  bool isScanning = true;
  bool isFlashOn = false;
  final MobileScannerController scannerController = MobileScannerController();

  void _goToResultScreen(String assetNumber) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ScanResultScreen(qrData: assetNumber),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("📷 สแกน QR Code"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: (capture) {
              if (!isScanning) return;
              final List<Barcode> barcodes = capture.barcodes;

              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  setState(() => isScanning = false);
                  _goToResultScreen(code);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ QR Code ไม่ถูกต้อง")),
                );
              }
            },
          ),

          // ✅ Overlay กรอบสแกน
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // กรอบโปร่งใส
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // เอฟเฟกต์สแกน
                AnimatedOpacity(
                  opacity: isScanning ? 1.0 : 0.0,
                  duration: const Duration(seconds: 1),
                  child: Container(
                    width: 250,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ ข้อความแนะนำ
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "วาง QR Code ให้อยู่ภายในกรอบ",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          // ✅ ปุ่มเปิด-ปิดแฟลช
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                icon: Icon(
                  isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: () {
                  setState(() => isFlashOn = !isFlashOn);
                  scannerController.toggleTorch();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
