import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:myapp/data/database_helper.dart';
import 'package:myapp/main.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/providers/currency_provider.dart';
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

  Future<void> _editName() async {
    final user = await _futureUser;
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);

    if (!mounted) return;
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, nameController.text);
            },
            child: const Text('Save'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Profile'),
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
                    onPressed: _editName,
                  ),
                );
              }
              return const ListTile(
                leading: CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person),
                ),
                title: Text('No user data'),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),
          SwitchListTile(
            title: const Text('Use System Theme'),
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
            title: const Text('App Color'),
            trailing: CircleAvatar(
              backgroundColor: themeProvider.color,
              radius: 15,
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Pick a color'),
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
                      child: const Text('Done'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Currency'),
          ListTile(
            title: const Text('Display Currency'),
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
          _buildSectionHeader(context, 'Database'),
          ListTile(
            title: const Text('Clear Database'),
            subtitle: const Text('Delete all transactions from the database.'),
            trailing: const Icon(Icons.delete_forever),
            onTap: () => _showClearDatabaseDialog(context),
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

  void _showClearDatabaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
              'Are you sure you want to delete all transactions? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                if (!mounted) return;
                final navigator = Navigator.of(dialogContext);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                await DatabaseHelper().deleteAllTransactions();
                
                navigator.pop();

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('All transactions have been deleted.'),
                      duration: Duration(seconds: 2),
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
