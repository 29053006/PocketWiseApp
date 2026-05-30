import 'package:flutter/material.dart';
import 'package:myapp/data/database_helper.dart';
import 'package:myapp/main.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
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
                // To toggle off system theme, we can default to light theme
                if (themeProvider.themeMode == ThemeMode.system) {
                  themeProvider.toggleTheme();
                }
              }
            },
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
              color: Theme.of(context).colorScheme.secondary,
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
                await DatabaseHelper().deleteAllTransactions();

                if (!mounted) return;

                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All transactions have been deleted.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
