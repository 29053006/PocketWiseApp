import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilterChip('All', isSelected: true),
                _buildFilterChip('Income'),
                _buildFilterChip('Expenses'),
                _buildFilterChip('Bills'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildDateHeader('TODAY'),
                  _buildTransactionItem(Icons.fastfood, 'Lunch with Team', 'Food & Dining - 12:45 PM', '-\$24.50', Colors.red),
                  _buildTransactionItem(Icons.shopping_bag, 'Grocery Store', 'Groceries - 09:30 AM', '-\$68.12', Colors.red),
                  _buildDateHeader('YESTERDAY'),
                  _buildTransactionItem(Icons.work, 'Monthly Salary', 'Work - 10:00 AM', '+\$3,200.00', Colors.green),
                  _buildTransactionItem(Icons.lightbulb, 'Electric Bill', 'Utilities - 04:15 PM', '-\$112.00', Colors.red),
                   _buildDateHeader('OCT 24'),
                  _buildTransactionItem(Icons.movie, 'Cinema Tickets', 'Entertainment - 08:30 PM', '-\$32.00', Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return Chip(
      label: Text(label),
      backgroundColor: isSelected ? const Color(0xFF00A86B) : Colors.grey[300],
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        date,
        style: GoogleFonts.lato(color: Colors.grey, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTransactionItem(
      IconData icon, String title, String subtitle, String amount, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: GoogleFonts.lato()),
        trailing: Text(
          amount,
          style: GoogleFonts.lato(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
