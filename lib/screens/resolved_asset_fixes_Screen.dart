import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FixedAssetsScreen extends StatefulWidget {
  @override
  _FixedAssetsScreenState createState() => _FixedAssetsScreenState();
}

class _FixedAssetsScreenState extends State<FixedAssetsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ครุภัณฑ์ที่ได้รับการแก้ไข'),
        backgroundColor: Colors.green,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 600;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child:
                    isWideScreen ? _buildWideFilters() : _buildNarrowFilters(),
              ),
              Expanded(
                child: StreamBuilder(
                  stream: _getFilteredStream(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    var fixes = snapshot.data!.docs;
                    if (fixes.isEmpty) {
                      return Center(
                        child: Text('ไม่มีครุภัณฑ์ที่ได้รับการแก้ไข'),
                      );
                    }

                    return ListView.builder(
                      itemCount: fixes.length,
                      itemBuilder: (context, index) {
                        var fix = fixes[index];
                        String formattedDate = '';
                        if (fix['resolved_at'] != null) {
                          Timestamp timestamp = fix['resolved_at'];
                          DateTime dateTime = timestamp.toDate();
                          formattedDate = DateFormat(
                            'dd MMM yyyy, HH:mm',
                          ).format(dateTime);
                        }
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: isWideScreen ? 50 : 10,
                            vertical: 5,
                          ),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              "ครุภัณฑ์: ${fix['asset_number']}",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "สถานะ: ${fix['status'] == 'fixed' ? 'แก้ไขแล้ว' : 'ไม่สามารถแก้ไขได้'}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        fix['status'] == 'fixed'
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                ),
                                if (fix['status'] == 'cannot_fix' &&
                                    fix['reason'] != null)
                                  Text(
                                    "เหตุผล: ${fix['reason']}",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                Text("แก้ไขเมื่อ: $formattedDate"),
                              ],
                            ),
                          ),
                        );
                      },
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

  Widget _buildWideFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _filterButtons(),
    );
  }

  Widget _buildNarrowFilters() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: _filterButtons(),
    );
  }

  List<Widget> _filterButtons() {
    return [
      FilterButton(
        text: 'ทั้งหมด',
        isSelected: selectedStatus == 'all',
        onTap: () => setState(() => selectedStatus = 'all'),
      ),
      FilterButton(
        text: 'แก้ไขได้',
        isSelected: selectedStatus == 'fixed',
        onTap: () => setState(() => selectedStatus = 'fixed'),
      ),
      FilterButton(
        text: 'ไม่สามารถแก้ไขได้',
        isSelected: selectedStatus == 'cannot_fix',
        onTap: () => setState(() => selectedStatus = 'cannot_fix'),
      ),
    ];
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    var collection = _firestore.collection('resolved_asset_fixes');
    if (selectedStatus == 'all') {
      return collection
          .where('status', whereIn: ['fixed', 'cannot_fix'])
          .orderBy('resolved_at', descending: true)
          .snapshots();
    } else {
      return collection
          .where('status', isEqualTo: selectedStatus)
          .orderBy('resolved_at', descending: true)
          .snapshots();
    }
  }
}

class FilterButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(text),
    );
  }
}
