import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool isExpense = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close), 
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Add Transaction', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'AMOUNT',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            Center(
              child: Text(
                '\$0,00',
                style: GoogleFonts.lato(fontSize: 64, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isExpense = true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isExpense ? Colors.red[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                          child: Text('Expense', style: TextStyle(fontWeight: isExpense ? FontWeight.bold : FontWeight.normal))),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isExpense = false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: !isExpense ? Colors.green[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                          child: Text('Income', style: TextStyle(fontWeight: !isExpense ? FontWeight.bold : FontWeight.normal))),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Select Category', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildCategoryCard(Icons.fastfood, 'Food'),
                _buildCategoryCard(Icons.directions_car, 'Transport'),
                _buildCategoryCard(Icons.home, 'Home'),
                _buildCategoryCard(Icons.shopping_bag, 'Shopping'),
                _buildCategoryCard(Icons.healing, 'Health'),
                _buildCategoryCard(Icons.movie, 'Movies'),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Date', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: '27/05/2026',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Note (Optional)', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'What was this for?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                   borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
             const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Saving this will put you at 82% of your monthly food budget.',
                       style: GoogleFonts.lato(color: Colors.green[800]),
                    ),
                  ),
                ],
              ),
            ),
             const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
               child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A86B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Save Transaction', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(IconData icon, String name) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: const Color(0xFF00A86B)),
          const SizedBox(height: 8),
          Text(name, style: GoogleFonts.lato()),
        ],
      ),
    );
  }
}
