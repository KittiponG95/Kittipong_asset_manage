import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditAssetScreen extends StatefulWidget {
  final String assetId;

  const EditAssetScreen({super.key, required this.assetId});

  @override
  _EditAssetScreenState createState() => _EditAssetScreenState();
}

class _EditAssetScreenState extends State<EditAssetScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _assetIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _purchaseDateController = TextEditingController();
  final TextEditingController _purchasePriceController =
      TextEditingController();
  final TextEditingController _storageLocationController =
      TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _warrantyNumberController =
      TextEditingController();
  final TextEditingController _responsiblePersonController =
      TextEditingController();
  final TextEditingController _additionalNotesController =
      TextEditingController();

  String _selectedStatus = 'กำลังใช้งาน';
  String _selectedCondition = 'ใช้งานได้ปกติ';

  Timestamp? _updatedAt; // เก็บค่า updated_at

  Future<void> _loadAssetData() async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection("assets")
              .doc(widget.assetId)
              .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _assetIdController.text = data['asset_id'];
          _nameController.text = data['name'];
          _typeController.text = data['type'];
          _brandController.text = data['brand'];
          _purchaseDateController.text = data['purchase_date'];
          _purchasePriceController.text = data['purchase_price'].toString();
          _storageLocationController.text = data['storage_location'];
          _expiryDateController.text = data['expiry_date'];
          _warrantyNumberController.text = data['warranty_number'];
          _responsiblePersonController.text = data['responsible_person'];
          _additionalNotesController.text = data['additional_notes'];
          _selectedStatus = data['status'] ?? 'กำลังใช้งาน';
          _selectedCondition = data['condition'] ?? 'ใช้งานได้ปกติ';
          _updatedAt = data['updated_at'];
        });
      }
    } catch (e) {
      print("Error loading asset data: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAssetData();
  }

  Future<void> _saveUpdatedAsset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("assets")
          .doc(widget.assetId)
          .update({
            "asset_id": _assetIdController.text.trim(),
            "name": _nameController.text.trim(),
            "type": _typeController.text.trim(),
            "brand": _brandController.text.trim(),
            "condition": _selectedCondition,
            "purchase_date": _purchaseDateController.text.trim(),
            "purchase_price":
                double.tryParse(_purchasePriceController.text.trim()) ?? 0.0,
            "storage_location": _storageLocationController.text.trim(),
            "status": _selectedStatus,
            "expiry_date": _expiryDateController.text.trim(),
            "warranty_number": _warrantyNumberController.text.trim(),
            "responsible_person": _responsiblePersonController.text.trim(),
            "additional_notes": _additionalNotesController.text.trim(),
            "image_url": '',
            "updated_at": Timestamp.now(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ข้อมูลครุภัณฑ์ถูกอัปเดตแล้ว")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("แก้ไขครุภัณฑ์")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                "รหัสครุภัณฑ์",
                _assetIdController,
                isEditable: false,
              ),
              _buildTextField("ชื่อครุภัณฑ์", _nameController),
              _buildTextField("ประเภทครุภัณฑ์", _typeController),
              _buildTextField("ยี่ห้อ / รุ่น", _brandController),
              _buildDropdownField(
                "สภาพ",
                _selectedCondition,
                ['ใช้งานได้ปกติ', 'ชำรุด'],
                (value) {
                  setState(() => _selectedCondition = value!);
                },
              ),
              _buildTextField("วันที่ซื้อ", _purchaseDateController),
              _buildTextField("ราคาซื้อ", _purchasePriceController),
              _buildTextField("สถานที่เก็บ", _storageLocationController),
              _buildDropdownField(
                "สถานะการใช้งาน",
                _selectedStatus,
                ['กำลังใช้งาน', 'เก็บ'],
                (value) {
                  setState(() => _selectedStatus = value!);
                },
              ),
              _buildTextField(
                "วันที่หมดอายุ / การใช้งาน",
                _expiryDateController,
              ),
              _buildTextField("หมายเลขประกัน", _warrantyNumberController),
              _buildTextField("ผู้รับผิดชอบ", _responsiblePersonController),
              _buildTextField(
                "รายละเอียดเพิ่มเติม",
                _additionalNotesController,
              ),
              if (_updatedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    "อัปเดตล่าสุด: ${DateFormat('dd/MM/yyyy HH:mm').format(_updatedAt!.toDate())}",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveUpdatedAsset,
                child: const Text("บันทึกการแก้ไข"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isEditable = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: isEditable, // ถ้า isEditable เป็น false จะไม่สามารถแก้ไขได้
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => value!.isEmpty ? "กรุณากรอก $label" : null,
      ),
    );
  }

  // Dropdown for selecting status and condition
  Widget _buildDropdownField(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value:
            options.contains(value) ? value : options.first, // ป้องกันค่า null
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
        items:
            options
                .toSet() // ป้องกันค่าซ้ำ
                .map<DropdownMenuItem<String>>(
                  (String option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  ),
                )
                .toList(),
        validator: (value) => value == null ? "กรุณาเลือก $label" : null,
      ),
    );
  }
}
