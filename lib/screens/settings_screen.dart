import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isReminderOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOfflineModeCard(),
            const SizedBox(height: 24),
            Text('REMINDERS', style: GoogleFonts.lato(color: Colors.grey, fontWeight: FontWeight.bold)),
            _buildRemindersCard(),
            const SizedBox(height: 24),
            Text('PRIVACY & DATA', style: GoogleFonts.lato(color: Colors.grey, fontWeight: FontWeight.bold)),
            _buildPrivacyCard(),
            const SizedBox(height: 24),
            Text('ABOUT', style: GoogleFonts.lato(color: Colors.grey, fontWeight: FontWeight.bold)),
            _buildAboutCard(),
            const SizedBox(height: 24),
            _buildPremiumCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineModeCard() {
    return Card(
      color: Colors.teal[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.teal[400]),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Offline Mode Active', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Your data is stored locally for maximum privacy.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Daily Local Reminder'),
            subtitle: const Text('Get a nudge to log your expenses'),
            value: isReminderOn,
            onChanged: (bool value) {
              setState(() {
                isReminderOn = value;
              });
            },
            activeColor: Colors.teal[400],
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Reminder Time'),
            trailing: Text('08:00 p.m.', style: GoogleFonts.lato(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.blue),
            title: const Text('Export Data (CSV)'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red[400]),
            title: Text('Clear All Data', style: TextStyle(color: Colors.red[400])),
            onTap: () {},
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Clearing your data is permanent. Since PocketWise operates in Offline Mode, we do not have backups on our servers.',
              style: GoogleFonts.lato(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            trailing: Text('2.4.1 (Build 890)', style: GoogleFonts.lato(color: Colors.grey)),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard() {
    return Card(
      color: Colors.teal[400],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PocketWise Premium', style: GoogleFonts.lato(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Unlock advanced analytics and multi-device sync.', style: GoogleFonts.lato(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.teal[400],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Upgrade Now'),
            ),
          ],
        ),
      ),
    );
  }
}
