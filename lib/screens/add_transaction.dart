import 'package:flutter/material.dart';
import 'package:myapp/data/database_helper.dart';
import 'package:myapp/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:myapp/main.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '0,00');
  final _noteController = TextEditingController();
  final _amountFocusNode = FocusNode();

  String _selectedType = 'Expense';
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  final Map<String, IconData> _expenseCategories = {
    'Food': Icons.fastfood,
    'Transport': Icons.directions_car,
    'Home': Icons.home,
    'Shopping': Icons.shopping_bag,
    'Health': Icons.health_and_safety,
    'Movies': Icons.movie,
  };

  final Map<String, IconData> _incomeCategories = {
    'Salary': Icons.work,
    'Bonus': Icons.card_giftcard,
    'Investment': Icons.trending_up,
    'Gift': Icons.cake,
    'Other': Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();
    _selectedCategory = _expenseCategories.keys.first;
    _amountFocusNode.addListener(() {
      if (_amountFocusNode.hasFocus && _amountController.text == '0,00') {
        _amountController.clear();
      } else if (!_amountFocusNode.hasFocus && _amountController.text.isEmpty) {
        _amountController.text = '0,00';
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
      }

      final newTransaction = Transaction(
        type: _selectedType,
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        description: _noteController.text,
      );

      await DatabaseHelper().insertTransaction(newTransaction);

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close), 
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              const SizedBox(height: 20),
              _buildAmountField(),
              const SizedBox(height: 30),
              _buildTransactionTypeSelector(),
              const SizedBox(height: 30),
              _buildCategorySelector(),
              const SizedBox(height: 30),
              _buildDateField(),
              const SizedBox(height: 30),
              _buildNoteField(),
              const SizedBox(height: 30),
              _buildBudgetInfo(),
              const SizedBox(height: 40),
              _buildSaveButton(themeProvider.color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      children: [
        Text(
          'AMOUNT',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '\$',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 200, 
              child: TextFormField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionTypeSelector() {
  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = 'Expense';
                _selectedCategory = _expenseCategories.keys.first;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedType == 'Expense' ? Colors.redAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  'Expense',
                  style: TextStyle(
                    color: _selectedType == 'Expense' ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = 'Income';
                _selectedCategory = _incomeCategories.keys.first;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedType == 'Income' ? Colors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  'Income',
                  style: TextStyle(
                    color: _selectedType == 'Income' ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildCategorySelector() {
    final categories = _selectedType == 'Expense' ? _expenseCategories : _incomeCategories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Category',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories.keys.elementAt(index);
            final icon = categories.values.elementAt(index);
            final isSelected = _selectedCategory == category;

            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(15),
                  border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(category, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined),
                const SizedBox(width: 12),
                Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

   Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note (Optional)',
           style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _noteController,
          decoration: InputDecoration(
            hintText: 'What was this for?',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetInfo() {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(context).colorScheme.primaryContainer,
        width: 1,
      ),
    ),
    child: Row(
      children: [
        Icon(
          Icons.info_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Saving this will put you at 82% of your monthly food budget.',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildSaveButton(Color buttonColor) {
    return ElevatedButton(
      onPressed: _submitData,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor, 
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Text('Save Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
