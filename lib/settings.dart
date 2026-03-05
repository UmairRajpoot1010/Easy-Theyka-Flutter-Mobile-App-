import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _isDarkMode = false;

  void _changePassword() async {
    // Show dialog to enter new password
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Change')),
        ],
      ),
    );
    if (result != null && result.length >= 6) {
      try {
        await FirebaseAuth.instance.currentUser?.updatePassword(result);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters.')));
    }
  }

  void _clearCache() async {
    // Simulate cache clear
    await Future.delayed(const Duration(milliseconds: 500));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared!')));
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Easy Theyka',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 Easy Theyka',
      children: [
        const SizedBox(height: 8),
        const Text('This app helps you find builders, manage jobs, and estimate construction costs.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: ListView(
          children: [
            const Text(
              'Settings',
              style: TextStyle(color: Colors.blueAccent, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.blueAccent),
              title: const Text('Change Password'),
              onTap: _changePassword,
            ),
            SwitchListTile(
              value: _isDarkMode,
              onChanged: (val) {
                setState(() => _isDarkMode = val);
                // You can implement actual dark mode switching here
              },
              title: const Text('Dark Mode'),
              secondary: const Icon(Icons.dark_mode, color: Colors.blueAccent),
            ),
            ListTile(
              leading: const Icon(Icons.cleaning_services, color: Colors.blueAccent),
              title: const Text('Clear Cache'),
              onTap: _clearCache,
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blueAccent),
              title: const Text('About'),
              onTap: _showAbout,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.blueAccent),
              title: const Text('Privacy Policy'),
              onTap: () {
                // You can show a privacy policy dialog or navigate to a privacy policy screen
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Privacy Policy'),
                    content: const Text('Your data is secure and will not be shared.'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
