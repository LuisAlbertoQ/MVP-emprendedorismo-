import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:front_genapp/ui/core/constants.dart';
import 'package:front_genapp/ui/core/theme.dart';

class GestionScreen extends StatelessWidget {
  const GestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ModuleCard(
            icon: Icons.account_tree,
            title: 'Consanguinidad',
            subtitle: 'Árbol genealógico y coeficiente de consanguinidad',
            onTap: () => context.push(AppRoutes.consanguinidad),
          ),
          const SizedBox(height: 12),
          _ModuleCard(
            icon: Icons.straighten,
            title: 'Fibra + Ranking',
            subtitle: 'Diámetro de fibra, confort, medulación y ranking',
            onTap: () => context.push(AppRoutes.fibraRanking),
          ),
          const SizedBox(height: 12),
          _ModuleCard(
            icon: Icons.favorite,
            title: 'Reproductivo',
            subtitle: 'Empadres y partos',
            onTap: () => context.push(AppRoutes.gestionReproductivo),
          ),
          const SizedBox(height: 12),
          _ModuleCard(
            icon: Icons.attach_money,
            title: 'Financiero',
            subtitle: 'Costos y ventas de fibra',
            onTap: () => context.push(AppRoutes.gestionFinanciero),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.2),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
