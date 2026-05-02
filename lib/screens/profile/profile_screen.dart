import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.surface,
              child: Icon(Icons.person_outline_rounded, size: 50, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text('Koffi Adewale', style: Theme.of(context).textTheme.displaySmall),
            Text('Membre depuis Janvier 2026', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 32),
            _buildProfileSection(context, 'Compte', [
              _ProfileItem(icon: Icons.person_outline, label: 'Informations personnelles'),
              _ProfileItem(icon: Icons.notifications_none, label: 'Notifications'),
              _ProfileItem(icon: Icons.security_outlined, label: 'Sécurité'),
            ]),
            _buildProfileSection(context, 'Préférences', [
              _ProfileItem(icon: Icons.language_rounded, label: 'Langue', trailing: 'Français'),
              _ProfileItem(icon: Icons.dark_mode_outlined, label: 'Mode sombre', trailing: 'Désactivé'),
            ]),
            _buildProfileSection(context, 'Autre', [
              _ProfileItem(icon: Icons.help_outline_rounded, label: 'Aide & Support'),
              _ProfileItem(icon: Icons.info_outline_rounded, label: 'À propos'),
            ]),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => context.go('/auth'),
              child: const Text('Déconnexion', style: TextStyle(color: AppColors.error)),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
          ),
        ),
        ...items,
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;

  const _ProfileItem({required this.icon, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.secondary),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing!,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.surface),
        ],
      ),
      onTap: () {},
    );
  }
}
