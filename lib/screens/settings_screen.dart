import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:myapp/data/database_helper.dart';
import 'package:myapp/main.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/providers/currency_provider.dart';
import 'package:myapp/providers/language_provider.dart';
import 'package:myapp/screens/budget_screen.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<User?>? _futureUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    setState(() {
      _futureUser = DatabaseHelper().getUser();
    });
  }

  Future<void> _editName(LanguageProvider lang) async {
    final user = await _futureUser;
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);

    if (!mounted) return;
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('edit_name')),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(hintText: lang.translate('edit_name_hint')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, nameController.text);
            },
            child: Text(lang.translate('save')),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      final updatedUser = User(id: user.id, name: newName, avatar: user.avatar);
      await DatabaseHelper().updateUser(updatedUser);
      _loadUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('settings')),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, languageProvider.translate('profile')),
          FutureBuilder<User?>(
            future: _futureUser,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData && snapshot.data != null) {
                final user = snapshot.data!;
                final imageBytes = user.avatar != null ? base64Decode(user.avatar!) : null;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                    child: imageBytes == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editName(languageProvider),
                  ),
                );
              }
              return ListTile(
                leading: const CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person),
                ),
                title: Text(languageProvider.translate('no_user_data')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: Text(languageProvider.translate('manage_budget')),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BudgetScreen()),
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, languageProvider.translate('appearance')),
          SwitchListTile(
            title: Text(languageProvider.translate('dark_mode')),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),
          SwitchListTile(
            title: Text(languageProvider.translate('use_system_theme')),
            value: themeProvider.themeMode == ThemeMode.system,
            onChanged: (value) {
              if (value) {
                themeProvider.setSystemTheme();
              } else {
                if (themeProvider.themeMode == ThemeMode.system) {
                  themeProvider.toggleTheme();
                }
              }
            },
          ),
          ListTile(
            title: Text(languageProvider.translate('app_color')),
            trailing: CircleAvatar(
              backgroundColor: themeProvider.color,
              radius: 15,
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(languageProvider.translate('app_color')),
                  content: SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: themeProvider.color,
                      onColorChanged: (color) {
                        themeProvider.setColor(color);
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(languageProvider.translate('save')),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, languageProvider.translate('currency')),
          ListTile(
            title: Text(languageProvider.translate('display_currency')),
            trailing: DropdownButton<String>(
              value: currencyProvider.currency,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  currencyProvider.setCurrency(newValue);
                }
              },
              items: <String>['USD', 'COP']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, languageProvider.translate('app_language')),
          ListTile(
            title: Text(languageProvider.translate('app_language')),
            trailing: DropdownButton<String>(
              value: languageProvider.locale.languageCode,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  languageProvider.setLanguage(newValue);
                }
              },
              items: <Map<String, String>>[
                {'code': 'en', 'name': 'English'},
                {'code': 'es', 'name': 'Español'},
              ].map<DropdownMenuItem<String>>((Map<String, String> lang) {
                return DropdownMenuItem<String>(
                  value: lang['code'],
                  child: Text(lang['name']!),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, languageProvider.translate('database')),
          ListTile(
            title: Text(languageProvider.translate('clear_database')),
            subtitle: Text(languageProvider.translate('clear_db_sub')),
            trailing: const Icon(Icons.delete_forever),
            onTap: () => _showClearDatabaseDialog(context, languageProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  void _showClearDatabaseDialog(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(lang.translate('confirm_deletion')),
          content: Text(lang.translate('clear_db_confirm_msg')),
          actions: <Widget>[
            TextButton(
              child: Text(lang.translate('cancel')),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(lang.translate('delete')),
              onPressed: () async {
                if (!mounted) return;
                final navigator = Navigator.of(dialogContext);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                await DatabaseHelper().deleteAllTransactions();
                
                navigator.pop();

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(lang.translate('db_cleared_msg')),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
