import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PocketWise', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistics', style: GoogleFonts.lato(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTimeFilter(),
            const SizedBox(height: 24),
            _buildExpensesByCategory(),
            const SizedBox(height: 24),
            _buildWeeklySpend(),
            const SizedBox(height: 24),
            _buildSmartTip(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: 'This Month',
          icon: const Icon(Icons.arrow_drop_down),
          items: <String>['This Month', 'Last Month', 'This Year'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: GoogleFonts.lato()),
            );
          }).toList(),
          onChanged: (_) {},
        ),
      ),
    );
  }

  Widget _buildExpensesByCategory() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Expenses by Category', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.info_outline, color: Colors.grey), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(color: Colors.teal[400], value: 40, title: '40%', radius: 50),
                    PieChartSectionData(color: Colors.grey[600], value: 30, title: '30%', radius: 50),
                    PieChartSectionData(color: Colors.teal[200], value: 15, title: '15%', radius: 50),
                    PieChartSectionData(color: Colors.grey[300], value: 15, title: '15%', radius: 50),
                  ],
                  centerSpaceRadius: 40,
                ),
              ),
            ),
             const SizedBox(height: 24),
            _buildLegendItem(Colors.teal[400]!, 'Food', '\$1,136', '40%'),
            _buildLegendItem(Colors.grey[600]!, 'Housing', '\$852', '30%'),
            _buildLegendItem(Colors.teal[200]!, 'Transport', '\$426', '15%'),
            _buildLegendItem(Colors.grey[300]!, 'Others', '\$426', '15%'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String name, String amount, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(width: 10, height: 10, color: color),
          const SizedBox(width: 8),
          Text(name, style: GoogleFonts.lato()),
          const Spacer(),
          Text(amount, style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(percentage, style: GoogleFonts.lato(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildWeeklySpend() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Spend', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Average \$660 / week', style: GoogleFonts.lato(color: Colors.grey)),
             const SizedBox(height: 24),
            SizedBox(
              height: 120,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                   barGroups: [
                    _buildBarGroup(0, 5),
                    _buildBarGroup(1, 3),
                    _buildBarGroup(2, 7),
                    _buildBarGroup(3, 4),
                  ],
                  titlesData: const FlTitlesData(
                     leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                       rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false)
                ),
              ),
            ),
             const SizedBox(height: 16),
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('8% less than last month', style: GoogleFonts.lato(color: Colors.green)),
                  Text('View Details', style: GoogleFonts.lato(color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
             )
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: Colors.teal[400], width: 15, borderRadius: const BorderRadius.all(Radius.circular(4)) )],
    );
  }


  Widget _buildSmartTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal[400],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Smart Tip', style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  'You\'ve spent 12% more on Food this week compared to your average. Dining out twice less next week could save you \$45.',
                  style: GoogleFonts.lato(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
