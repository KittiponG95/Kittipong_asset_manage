import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('assets').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          int totalAssets = snapshot.data!.docs.length;
          int damagedAssets =
              snapshot.data!.docs
                  .where((doc) => doc['condition'] == 'ชำรุด')
                  .length;
          int operationalAssets = totalAssets - damagedAssets;

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDashboardCard(
                  'ครุภัณฑ์ทั้งหมด',
                  totalAssets,
                  Icons.inventory,
                  Colors.blue,
                ),
                _buildDashboardCard(
                  'ครุภัณฑ์ชำรุด',
                  damagedAssets,
                  Icons.warning,
                  Colors.red,
                ),
                _buildDashboardCard(
                  'ครุภัณฑ์ใช้งานได้',
                  operationalAssets,
                  Icons.check_circle,
                  Colors.green,
                ),
                SizedBox(height: 20),
                Expanded(
                  child: _buildPieChart(damagedAssets, operationalAssets),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: color, size: 40),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(int damaged, int operational) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            color: Colors.red,
            value: damaged.toDouble(),
            title: 'ชำรุด\n$damaged',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.green,
            value: operational.toDouble(),
            title: 'ใช้งานได้\n$operational',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
