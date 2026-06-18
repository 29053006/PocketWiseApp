import 'package:flutter/material.dart';
import 'package:myapp/data/database_helper.dart';
import 'package:myapp/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/language_provider.dart';
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

  String _selectedType = 'Income';
  String _selectedCategory = 'Salary';
  DateTime _selectedDate = DateTime.now();

  final Map<String, IconData> _expenseCategories = {
    'Food': Icons.fastfood,
    'Transport': Icons.directions_car,
    'Home': Icons.home,
    'Shopping': Icons.shopping_bag,
    'Health': Icons.health_and_safety,
    'Movies': Icons.movie,
    'Other': Icons.more_horiz,
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
    _selectedCategory = _incomeCategories.keys.first;
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

  void _submitData(LanguageProvider lang) async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.translate('enter_valid_amount'))),
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
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20), 
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(lang.translate('new_transaction')),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              const SizedBox(height: 10),
              _buildAmountField(lang),
              const SizedBox(height: 30),
              _buildTransactionTypeSelector(lang),
              const SizedBox(height: 30),
              _buildCategorySelector(lang),
              const SizedBox(height: 30),
              _buildDateField(lang),
              const SizedBox(height: 30),
              _buildNoteField(lang),
              const SizedBox(height: 30),
              _buildBudgetInfo(lang),
              const SizedBox(height: 40),
              _buildSaveButton(themeProvider.color, lang),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField(LanguageProvider lang) {
    return Column(
      children: [
        Text(
          lang.translate('amount_label'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                fontSize: 40,
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
                    return lang.translate('enter_amount_error');
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

  Widget _buildTransactionTypeSelector(LanguageProvider lang) {
    return Center(
      child: SegmentedButton<String>(
        segments: [
          ButtonSegment(value: 'Income', label: Text(lang.translate('income')), icon: const Icon(Icons.next_plan_outlined)),
          ButtonSegment(value: 'Expense', label: Text(lang.translate('expenses')), icon: const Icon(Icons.outbound_outlined))
        ],
        selected: {_selectedType},
        onSelectionChanged: (Set<String> newSelection) {
          setState(() {
            _selectedType = newSelection.first;
            _selectedCategory = _selectedType == 'Expense' 
              ? _expenseCategories.keys.first 
              : _incomeCategories.keys.first;
          });
        },
      ),
    );
  }
  Widget _buildCategorySelector(LanguageProvider lang) {
    final categories = _selectedType == 'Expense' ? _expenseCategories : _incomeCategories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.translate('select_category'),
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
                  color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(15),
                  border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(lang.translate(category.toLowerCase()), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateField(LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.translate('date'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

   Widget _buildNoteField(LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.translate('note'),
           style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _noteController,
          decoration: InputDecoration(
            hintText: lang.translate(_selectedCategory = _selectedType == 'Expense' 
              ? 'what_was_this_for'
              : 'where_did_this_come_from'),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetInfo(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
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
          Expanded(
            child: Text(
              '${lang.translate('budget_info_msg_start')}82${lang.translate('budget_info_msg_end')}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSaveButton(Color buttonColor, LanguageProvider lang) {
    return ElevatedButton(
      onPressed: () => _submitData(lang),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor, 
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(lang.translate('save_transaction'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
