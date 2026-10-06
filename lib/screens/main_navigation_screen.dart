import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'projects_screen.dart';

/// Root navigation shell that provides bottom navigation between:
/// 1. [HomeScreen] — Executive Dashboard with Real-time Analytics
/// 2. [ProjectsScreen] — Full Projects Catalog & Task Management
/// 3. [ProfileScreen] — User Profile & Workspace Settings
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onNavigateToProjects: () => _onTabSelected(1),
            onNavigateToProfile: () => _onTabSelected(2),
          ),
          const ProjectsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.14),
            height: 64,
            elevation: 0,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(
                  Icons.home_rounded,
                  color: AppTheme.primaryColor,
                ),
                label: context.tr('dashboard'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.folder_outlined),
                selectedIcon: const Icon(
                  Icons.folder_rounded,
                  color: AppTheme.primaryColor,
                ),
                label: context.tr('projects'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(
                  Icons.person_rounded,
                  color: AppTheme.primaryColor,
                ),
                label: context.tr('profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
