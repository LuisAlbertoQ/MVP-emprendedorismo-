import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:front_genapp/ui/core/theme.dart';

class HomeShell extends StatelessWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/animales')) {
      currentIndex = 1;
    } else if (location.startsWith('/perfil')) {
      currentIndex = 2;
    } else if (location.startsWith('/reportes')) {
      currentIndex = 3;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primaryLight.withValues(alpha: 0.2),
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/animales');
              break;
            case 2:
              context.go('/perfil');
              break;
            case 3:
              context.go('/reportes');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets),
            selectedIcon: Icon(Icons.pets, color: AppTheme.primary),
            label: 'Animales',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            selectedIcon: Icon(Icons.person, color: AppTheme.primary),
            label: 'Perfil',
          ),
          NavigationDestination(
            icon: Icon(Icons.description),
            selectedIcon: Icon(Icons.description, color: AppTheme.primary),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }
}
