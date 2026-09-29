import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../providers/saved_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/state_views.dart';
import '../auth/login_screen.dart';

/// Profile tab: email, saved count, light / dark theme and logout.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to see your saved photos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await AuthService().logout();
    if (!context.mounted) return;

    // Clear the whole stack so Back can't return to the app after logout.
    Navigator.of(context).pushAndRemoveUntil(
      fadeRoute(const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final email = AuthService().currentEmail ?? '';
    final savedCount = context.select<SavedProvider, int>((s) => s.count);
    final themeMode = context.select<ThemeProvider, ThemeMode>((t) => t.mode);

    final initials = email.isEmpty
        ? '?'
        : email.substring(0, email.length >= 2 ? 2 : 1).toUpperCase();

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeader(title: 'Profile'),
          Expanded(
            child: ListView(
              primary: false,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.border, width: 2),
                    ),
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                _ProfileCard(
                  child: Row(
                    children: [
                      Icon(Icons.bookmark, color: p.textPrimary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Saved photos',
                          style: TextStyle(
                            fontSize: 16,
                            color: p.textPrimary,
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Text(
                          '$savedCount',
                          key: ValueKey(savedCount),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: p.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ProfileCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.brightness_6_outlined,
                              color: p.textPrimary),
                          const SizedBox(width: 12),
                          Text(
                            'Theme',
                            style: TextStyle(
                              fontSize: 16,
                              color: p.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_outlined, size: 18),
                              label: Text('Light'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_outlined, size: 18),
                              label: Text('Dark'),
                            ),
                          ],
                          selected: {themeMode},
                          onSelectionChanged: (selection) {
                            context
                                .read<ThemeProvider>()
                                .setMode(selection.first);
                          },
                          style: SegmentedButton.styleFrom(
                            foregroundColor: p.textPrimary,
                            selectedForegroundColor: p.onPrimary,
                            selectedBackgroundColor: p.primary,
                            side: BorderSide(color: p.border),
                            padding:
                            const EdgeInsets.symmetric(horizontal: 6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD64545),
                    side: const BorderSide(color: Color(0xFFD64545)),
                    shape: const StadiumBorder(),
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Widget child;

  const _ProfileCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: child,
    );
  }
}