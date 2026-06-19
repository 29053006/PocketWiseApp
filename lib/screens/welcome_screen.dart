import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:myapp/main.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database_helper.dart';
import '../models/user_model.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      
      final dbHelper = DatabaseHelper();
      final user = User(
        name: _nameController.text,
      );
      await dbHelper.insertUser(user);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstTime', false);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.05),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(colorScheme, lang),
                  const SizedBox(height: 60),
                  _buildInputSection(colorScheme, lang),
                  const SizedBox(height: 40),
                  _buildContinueButton(themeProvider.color, colorScheme, lang),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      lang.translate('data_local_secure'),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SvgPicture.asset(
            'assets/images/logo.svg',
            height: 40,
            colorFilter: ColorFilter.mode(colorScheme.primary, BlendMode.srcIn),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          lang.translate('welcome_title'),
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          lang.translate('smart_tracking_sub'),
          style: TextStyle(
            fontSize: 18,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection(ColorScheme colorScheme, LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.translate('whats_your_name'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: lang.translate('name_hint'),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return lang.translate('name_error');
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContinueButton(Color buttonColor, ColorScheme colorScheme, LanguageProvider lang) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _saveAndContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          elevation: 8,
          shadowColor: buttonColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isSubmitting
                ? const SizedBox(
                    key: ValueKey('loading'),
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    key: const ValueKey('button_content'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lang.translate('get_started'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
          ),
      ),
    );
  }
}
