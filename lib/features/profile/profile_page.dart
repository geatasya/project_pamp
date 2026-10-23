import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../auth/presentation/auth_provider.dart';
import '../event/presentation/event_provider.dart';

void logoutUser(BuildContext context) {
  context.read<EventProvider>().clear();
  context.read<AuthProvider>().logout();
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = context.watch<EventProvider>();
    final email = auth.email ?? '-';
    final name = email.split('@').first;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Profil'),
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    InitialAvatar(text: email, size: 84),
                    const SizedBox(height: 14),
                    Text(name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(email,
                        style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _stat('Event', '${p.allEvents.length}', AppColors.purple),
                  const SizedBox(width: 10),
                  _stat('Wishlist', '${p.favoriteCount}', AppColors.red),
                  const SizedBox(width: 10),
                  _stat('Dikunjungi', '${p.visitedCount}', AppColors.green),
                ],
              ),
              const SizedBox(height: 14),
              const SoftCard(
                child: Row(
                  children: [
                    IconTile(
                        icon: Icons.cloud_done_outlined,
                        color: AppColors.green,
                        bg: AppColors.greenBg),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                          'Data event kamu tersimpan aman di Supabase Cloud dan hanya bisa diakses akunmu.',
                          style: TextStyle(
                              fontSize: 13, height: 1.45, color: AppColors.muted)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: BorderSide(color: AppColors.red.withAlpha(90))),
                onPressed: () => logoutUser(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Expanded(
        child: SoftCard(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ),
      );
}

/// Halaman sementara untuk fitur anggota kelompok lain.
class PlaceholderPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(title),
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTile(
                  icon: icon,
                  color: AppColors.purple,
                  bg: AppColors.purpleBg,
                  size: 84),
              const SizedBox(height: 18),
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}
