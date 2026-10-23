import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/ui_kit.dart';
import '../auth/presentation/auth_provider.dart';
import '../event/presentation/event_list_page.dart';
import '../profile/profile_page.dart';

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

const _items = [
  _NavItem(Icons.event_note_outlined, Icons.event_note_rounded, 'Jadwal Konser'),
  _NavItem(Icons.confirmation_number_outlined,
      Icons.confirmation_number_rounded, 'Tiket Saya'),
  _NavItem(Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet_rounded, 'Tabungan'),
  _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
];

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _pages = const <Widget>[
    EventListPage(),
    PlaceholderPage(
      title: 'Tiket Saya',
      subtitle:
          'Riwayat tiket yang sudah dibeli.\nFitur ini dikerjakan anggota kelompok lain (Fitur 2).',
      icon: Icons.confirmation_number_rounded,
    ),
    PlaceholderPage(
      title: 'Tabungan',
      subtitle:
          'Target tabungan tiket konser.\nFitur ini dikerjakan anggota kelompok lain (Fitur 3).',
      icon: Icons.account_balance_wallet_rounded,
    ),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    final stack = IndexedStack(index: _index, children: _pages);

    if (wide) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Row(
          children: [
            _sidebar(context),
            Expanded(child: stack),
          ],
        ),
      );
    }
    return Scaffold(
      body: stack,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _index = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              _index == i
                                  ? _items[i].activeIcon
                                  : _items[i].icon,
                              size: 26,
                              color: _index == i
                                  ? AppColors.ink
                                  : AppColors.muted),
                          const SizedBox(height: 4),
                          Text(_items[i].label,
                              maxLines: 1,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: _index == i
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: _index == i
                                      ? AppColors.ink
                                      : AppColors.muted)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sidebar(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.email ?? '-';
    return Container(
      width: 262,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const LogoMark(size: 46),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CONCERT RADAR',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted)),
                  BrandText(fontSize: 22),
                ],
              ),
            ],
          ),
          const SizedBox(height: 34),
          for (var i = 0; i < _items.length; i++) ...[
            Material(
              color: _index == i ? AppColors.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _index = i),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                          _index == i ? _items[i].activeIcon : _items[i].icon,
                          size: 22,
                          color: _index == i ? Colors.white : AppColors.muted),
                      const SizedBox(width: 12),
                      Text(_items[i].label,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color:
                                  _index == i ? Colors.white : AppColors.ink)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.subtle,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                InitialAvatar(text: email, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppColors.red,
                side: BorderSide(color: AppColors.red.withAlpha(90))),
            onPressed: () => logoutUser(context),
            icon: const Icon(Icons.logout_rounded, size: 19),
            label: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
