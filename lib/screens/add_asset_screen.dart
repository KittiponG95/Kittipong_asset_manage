import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key});

  @override
  _AddAssetScreenState createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _assetIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController(
    text: 'ใช้งานได้ปกติ',
  ); // กำหนดค่าเริ่มต้นเป็น 'ใช้งานได้ปกติ'
  final TextEditingController _purchaseDateController = TextEditingController();
  final TextEditingController _purchasePriceController =
      TextEditingController();
  final TextEditingController _storageLocationController =
      TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _warrantyNumberController =
      TextEditingController();
  final TextEditingController _responsiblePersonController =
      TextEditingController();
  final TextEditingController _additionalNotesController =
      TextEditingController();
  final TextEditingController _fiscalYearController = TextEditingController();

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // บันทึกข้อมูลลง Firestore
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection("assets")
          .add({
            "asset_id": _assetIdController.text.trim(),
            "name": _nameController.text.trim(),
            "type": _typeController.text.trim(),
            "brand": _brandController.text.trim(),
            "condition": _conditionController.text.trim(),
            "purchase_date": _purchaseDateController.text.trim(),
            "purchase_price":
                double.tryParse(_purchasePriceController.text.trim()) ?? 0.0,
            "storage_location": _storageLocationController.text.trim(),
            "status": _statusController.text.trim(),
            "expiry_date": _expiryDateController.text.trim(),
            "warranty_number": _warrantyNumberController.text.trim(),
            "responsible_person": _responsiblePersonController.text.trim(),
            "additional_notes": _additionalNotesController.text.trim(),
            "fiscal_year": _fiscalYearController.text.trim(),
            "created_at": FieldValue.serverTimestamp(),
          });

      // ดึงข้อมูล created_at หลังจากบันทึกแล้ว
      DocumentSnapshot snapshot = await docRef.get();
      Timestamp timestamp = snapshot['created_at'];
      print('Asset created at: ${timestamp.toDate()}'); // แสดงเวลาที่บันทึก

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("เพิ่มครุภัณฑ์เรียบร้อย!")));
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
      appBar: AppBar(
        title: const Text("เพิ่มครุภัณฑ์"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("รหัสครุภัณฑ์", _assetIdController),
              _buildTextField("ชื่อครุภัณฑ์", _nameController),
              _buildTextField("ประเภทครุภัณฑ์", _typeController),
              _buildTextField("ยี่ห้อ / รุ่น", _brandController),
              // ลบฟิลด์ "สภาพ" ออก
              _buildTextField(
                "ปีงบประมาณ",
                _fiscalYearController,
              ), // ปีงบประมาณ
              _buildDateField("วันที่ซื้อ", _purchaseDateController),
              _buildTextField("ราคาซื้อ", _purchasePriceController),
              _buildTextField("สถานที่เก็บ", _storageLocationController),
              _buildStatusField(),
              _buildDateField(
                "วันที่หมดอายุ / การใช้งาน",
                _expiryDateController,
              ),
              _buildTextField("หมายเลขประกัน", _warrantyNumberController),
              _buildTextField("ผู้รับผิดชอบ", _responsiblePersonController),
              _buildTextField(
                "รายละเอียดเพิ่มเติม",
                _additionalNotesController,
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveAsset,
                child: const Text("บันทึก"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => value!.isEmpty ? "กรุณากรอก $label" : null,
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        onTap: () => _selectDate(context, controller),
        validator: (value) => value!.isEmpty ? "กรุณาเลือก $label" : null,
      ),
    );
  }

  Widget _buildStatusField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "สถานะการใช้งาน",
          border: const OutlineInputBorder(),
        ),
        value: _statusController.text.isEmpty ? null : _statusController.text,
        onChanged: (newValue) {
          setState(() {
            _statusController.text = newValue!;
          });
        },
        items: [
          DropdownMenuItem(value: "กำลังใช้งาน", child: Text("กำลังใช้งาน")),
          DropdownMenuItem(value: "เก็บ", child: Text("เก็บ")),
        ],
        validator: (value) => value == null ? "กรุณาเลือกสถานะการใช้งาน" : null,
      ),
    );
  }
}
