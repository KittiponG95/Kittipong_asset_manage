import 'package:flutter/material.dart';
import 'search_result_screen.dart';

class SearchAssetScreen extends StatefulWidget {
  const SearchAssetScreen({super.key});

  @override
  State<SearchAssetScreen> createState() => _SearchAssetScreenState();
}

class _SearchAssetScreenState extends State<SearchAssetScreen> {
  final TextEditingController _textController = TextEditingController();

  void _searchAsset() {
    String assetNumber = _textController.text.trim();

    if (assetNumber.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultScreen(qrData: assetNumber),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ กรุณากรอกหมายเลขครุภัณฑ์"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50], // สีพื้นหลังอ่อนๆ
      appBar: AppBar(
        title: const Text("🔍 ค้นหาครุภัณฑ์"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            elevation: 6, // เพิ่มเงาให้การ์ดดูโดดเด่น
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "🔢 กรอกหมายเลขครุภัณฑ์",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // ช่องกรอกหมายเลขครุภัณฑ์
                  TextField(
                    controller: _textController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.inventory_2),
                      labelText: "หมายเลขครุภัณฑ์",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ปุ่มค้นหา
                  ElevatedButton.icon(
                    onPressed: _searchAsset,
                    icon: const Icon(Icons.search),
                    label: const Text("ค้นหา"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 12,
                      ),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
