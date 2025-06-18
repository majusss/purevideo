import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: _CustomBottomNavigationBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) {
          if (index == widget.navigationShell.currentIndex) return;

          HapticFeedback.mediumImpact();

          widget.navigationShell.goBranch(
            index,
            initialLocation: false,
          );
        },
      ),
    );
  }
}

class _CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _CustomBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60 + MediaQuery.of(context).padding.bottom,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavBarItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Główna',
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavBarItem(
                  icon: Icons.search_outlined,
                  activeIcon: Icons.search,
                  label: 'Szukaj',
                  isSelected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                _NavBarItem(
                  icon: Icons.category_outlined,
                  activeIcon: Icons.category,
                  label: 'Kategorie',
                  isSelected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
                _NavBarItem(
                  icon: Icons.bookmark_outline,
                  activeIcon: Icons.bookmark,
                  label: 'Moja lista',
                  isSelected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
                _NavBarItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Ustawienia',
                  isSelected: currentIndex == 4,
                  onTap: () => onTap(4),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
          highlightColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.2),
          child: SizedBox(
            width: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
