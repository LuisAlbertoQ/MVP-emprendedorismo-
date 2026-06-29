import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:front_genapp/ui/core/constants.dart';
import 'package:front_genapp/ui/core/theme.dart';

class FinancieroScreen extends StatelessWidget {
  const FinancieroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financiero')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ModuleCard(
            icon: Icons.account_balance_wallet,
            title: 'Costos',
            subtitle: 'Gastos de alimentación, sanidad, esquila y más',
            onTap: () => context.push(AppRoutes.costos),
          ),
          const SizedBox(height: 12),
          _ModuleCard(
            icon: Icons.sell,
            title: 'Ventas de Fibra',
            subtitle: 'Registro de ventas de fibra por animal',
            onTap: () => context.push(AppRoutes.ventasFibra),
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
