import 'package:flutter/material.dart';
import '../../routes.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFADF8E),
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        children: [
          _SettingsSection(
            title: 'Profile',
            tiles: [
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Update personal details',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.editProfile);
                },
              ),
            ],
          ),

          _SettingsSection(
            title: 'Security',
            tiles: [
              _SettingsTile(
                icon: Icons.lock_outline,
                title: 'Change password',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.changePassword);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsTile> tiles;
  const _SettingsSection({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
          ),
        ),
        Material(
          color: Colors.white,
          child: Column(children: tiles),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
