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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(lang.translate('edit_name')),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: lang.translate('edit_name_hint'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
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

    if (newName != null && newName.trim().isNotEmpty) {
      final updatedUser = User(id: user.id, name: newName.trim(), avatar: user.avatar);
      await DatabaseHelper().updateUser(updatedUser);
      _loadUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.translate('settings'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // Profile section header with modern styling
          FutureBuilder<User?>(
            future: _futureUser,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData && snapshot.data != null) {
                final user = snapshot.data!;
                final imageBytes = user.avatar != null ? base64Decode(user.avatar!) : null;
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.15),
                        colorScheme.primary.withValues(alpha: 0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.primary,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                              child: imageBytes == null 
                                ? Icon(Icons.person, size: 38, color: colorScheme.onSurfaceVariant) 
                                : null,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () => _editName(languageProvider),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: colorScheme.surface, width: 2),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              languageProvider.translate('data_local_secure'),
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      languageProvider.translate('no_user_data'),
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            },
          ),

          // High-end Budget health link card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetScreen()),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_outlined,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageProvider.translate('manage_budget'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            languageProvider.translate('budget_health'),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Appearance Group
          _buildSettingsGroup(
            title: languageProvider.translate('appearance'),
            children: [
              _buildSettingsTile(
                icon: Icons.dark_mode_outlined,
                iconColor: Colors.amber.shade700,
                title: languageProvider.translate('dark_mode'),
                trailing: Switch(
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
              _buildSettingsTile(
                icon: Icons.settings_brightness_outlined,
                iconColor: Colors.blue.shade600,
                title: languageProvider.translate('use_system_theme'),
                trailing: Switch(
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
              ),
              _buildSettingsTile(
                icon: Icons.color_lens_outlined,
                iconColor: themeProvider.color,
                title: languageProvider.translate('app_color'),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: themeProvider.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                ),
                onTap: () => _showColorPickerDialog(context, themeProvider, languageProvider),
              ),
            ],
          ),

          // Preferences Group (Currency & Language)
          _buildSettingsGroup(
            title: languageProvider.translate('currency'),
            children: [
              _buildSettingsTile(
                icon: Icons.monetization_on_outlined,
                iconColor: Colors.green.shade600,
                title: languageProvider.translate('display_currency'),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currencyProvider.currency,
                    dropdownColor: colorScheme.surface,
                    icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurfaceVariant),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        currencyProvider.setCurrency(newValue);
                      }
                    },
                    items: <String>['USD', 'COP']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              _buildSettingsTile(
                icon: Icons.translate_outlined,
                iconColor: Colors.purple.shade600,
                title: languageProvider.translate('app_language'),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: languageProvider.locale.languageCode,
                    dropdownColor: colorScheme.surface,
                    icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurfaceVariant),
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
                        child: Text(
                          lang['name']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          // Database Group (Danger Zone)
          _buildSettingsGroup(
            title: languageProvider.translate('database'),
            isDangerZone: true,
            children: [
              _buildSettingsTile(
                icon: Icons.delete_forever_outlined,
                iconColor: Colors.red.shade600,
                title: languageProvider.translate('clear_database'),
                subtitle: languageProvider.translate('clear_db_sub'),
                onTap: () => _showClearDatabaseDialog(context, languageProvider),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({
    required String title,
    required List<Widget> children,
    bool isDangerZone = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardBorderColor = isDangerZone 
      ? Colors.red.withValues(alpha: 0.2) 
      : colorScheme.outline.withValues(alpha: 0.1);
    final cardBgColor = isDangerZone
      ? Colors.red.withValues(alpha: 0.015)
      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.12);

    final List<Widget> separatedChildren = [];
    for (int i = 0; i < children.length; i++) {
      separatedChildren.add(children[i]);
      if (i < children.length - 1) {
        separatedChildren.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(
              color: isDangerZone 
                ? Colors.red.withValues(alpha: 0.1) 
                : colorScheme.outline.withValues(alpha: 0.08),
              height: 1,
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 20.0, bottom: 8.0),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: isDangerZone 
                ? Colors.red.shade400 
                : colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: cardBorderColor,
              width: 1.5,
            ),
          ),
          color: cardBgColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              children: separatedChildren,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void _showColorPickerDialog(
    BuildContext context,
    ThemeProvider themeProvider,
    LanguageProvider languageProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          languageProvider.translate('app_color'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
  }

  void _showClearDatabaseDialog(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                lang.translate('confirm_deletion'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(lang.translate('clear_db_confirm_msg')),
          actions: <Widget>[
            TextButton(
              child: Text(lang.translate('cancel')),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(
                lang.translate('delete'),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
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
