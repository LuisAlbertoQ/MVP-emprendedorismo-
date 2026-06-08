import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front_genapp/ui/core/constants.dart';
import 'package:front_genapp/ui/core/theme.dart';
import 'package:front_genapp/ui/features/auth/providers/auth_provider.dart';
import 'package:front_genapp/ui/features/animales/providers/animal_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumenAsync = ref.watch(resumenProvider);
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hola, ${user?.firstName.isNotEmpty == true ? user!.firstName : 'usuario'}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go(AppRoutes.perfil),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(resumenProvider);
          ref.read(authProvider.notifier).loadPerfil();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PlanBanner(user: user),
            const SizedBox(height: 20),
            resumenAsync.when(
              data: (r) => _StatsGrid(resumen: r),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 20),
            _QuickActions(),
          ],
        ),
      ),
    );
  }
}

class _PlanBanner extends StatelessWidget {
  final dynamic user;
  const _PlanBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    final plan = user?.plan ?? 'gratuito';
    final used = user?.animalesCount ?? 0;
    final limit = user?.limiteAnimales ?? 20;
    final ratio = limit > 0 ? used / limit : 0.0;
    final planColors = {
      'gratuito': Colors.grey,
      'basico': Colors.blue,
      'criador': AppTheme.accent,
    };
    final planLabels = {
      'gratuito': 'Gratuito',
      'basico': 'Básico',
      'criador': 'Criador',
    };
    return Card(
      color: planColors[plan]?.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.workspace_premium,
                size: 40, color: planColors[plan]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan ${planLabels[plan] ?? plan}',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: planColors[plan],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$used / $limit animales',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> resumen;
  const _StatsGrid({required this.resumen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = resumen['total'] as int? ?? 0;
    final machos = resumen['machos'] as int? ?? 0;
    final hembras = resumen['hembras'] as int? ?? 0;
    final alpaca = resumen['alpaca'] as int? ?? 0;
    final llama = resumen['llama'] as int? ?? 0;
    final ovino = resumen['ovino'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resumen',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.pets,
                label: 'Total',
                value: '$total',
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.male,
                label: 'Machos',
                value: '$machos',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.female,
                label: 'Hembras',
                value: '$hembras',
                color: Colors.pink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Especies',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SpeciesCard(
                emoji: '🦙',
                label: 'Alpaca',
                value: '$alpaca',
                color: Colors.brown,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SpeciesCard(
                emoji: '🐑',
                label: 'Llama',
                value: '$llama',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SpeciesCard(
                emoji: '🐏',
                label: 'Ovino',
                value: '$ovino',
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    )),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    )),
          ],
        ),
      ),
    );
  }
}

class _SpeciesCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  const _SpeciesCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    )),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    )),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acciones Rápidas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionChip(
                icon: Icons.add,
                label: 'Nuevo Animal',
                onTap: () => context.push(AppRoutes.animalesCrear),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionChip(
                icon: Icons.list,
                label: 'Ver Todos',
                onTap: () => context.go(AppRoutes.animales),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionChip(
                icon: Icons.description,
                label: 'Reportes',
                onTap: () => context.go(AppRoutes.reportes),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(height: 4),
              Text(label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
            ],
          ),
        ),
      ),
    );
  }
}
