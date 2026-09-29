import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../home/home_feed_screen.dart';
import '../profile/profile_screen.dart';
import '../saved/saved_screen.dart';
import '../search/search_screen.dart';

/// The signed-in app: four tabs behind a bottom navigation bar.
///
/// All visited tabs stay mounted in a Stack (only the active one is visible).
/// That is what keeps each tab's scroll position and loaded content when you
/// switch away and back. A plain "swap the body" approach would rebuild the
/// tab and lose both. Tabs are built lazily, the first time they're opened.
///
/// Switching cross-fades (and nudges) the tabs instead of snapping.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final Set<int> _visited = <int>{0};

  Widget _buildTab(int i) {
    switch (i) {
      case 0:
        return const HomeFeedScreen();
      case 1:
        return const SearchScreen();
      case 2:
        return const SavedScreen();
      default:
        return const ProfileScreen();
    }
  }

  void _select(int i) {
    if (i == _index) return;
    // Drop the keyboard if the Search field had focus.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _index = i;
      _visited.add(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return PopScope(
      // Back on any other tab returns to Home first; Back on Home exits.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < 4; i++)
              _TabPage(
                active: i == _index,
                child: _visited.contains(i)
                    ? _buildTab(i)
                    : const SizedBox.shrink(),
              ),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: p.card,
            border: Border(top: BorderSide(color: p.border)),
          ),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: _select,
            type: BottomNavigationBarType.fixed,
            backgroundColor: p.card,
            elevation: 0,
            selectedItemColor: p.textPrimary,
            unselectedItemColor: p.textSecondary,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                activeIcon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark_border),
                activeIcon: Icon(Icons.bookmark),
                label: 'Saved',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps one tab: fades it in / out, ignores touches while hidden, and pauses
/// its animations while hidden (TickerMode) so hidden tabs cost nothing.
class _TabPage extends StatelessWidget {
  final bool active;
  final Widget child;

  const _TabPage({required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: AnimatedSlide(
        offset: active ? Offset.zero : const Offset(0, 0.02),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: IgnorePointer(
          ignoring: !active,
          child: TickerMode(enabled: active, child: child),
        ),
      ),
    );
  }
}