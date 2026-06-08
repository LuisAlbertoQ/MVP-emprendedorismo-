import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_genapp/data/models/user_model.dart';
import 'package:front_genapp/ui/core/theme.dart';
import 'package:front_genapp/ui/features/auth/providers/auth_provider.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    if (user == null) {
      ref.read(authProvider.notifier).loadPerfil();
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(user: user),
          const SizedBox(height: 24),
          _PlanCard(user: user, ref: ref),
          const SizedBox(height: 24),
          _InfoCard(user: user),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final UserModel user;
  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.2),
          child: Icon(Icons.person, size: 40, color: AppTheme.primary),
        ),
        const SizedBox(height: 12),
        Text(
          user.firstName.isNotEmpty ? user.firstName : user.telefono,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          user.telefono,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final UserModel user;
  final WidgetRef ref;
  const _PlanCard({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium,
                    color: planColors[user.plan] ?? Colors.grey),
                const SizedBox(width: 8),
                Text('Plan ${planLabels[user.plan] ?? user.plan}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: user.limiteAnimales > 0
                  ? user.animalesCount / user.limiteAnimales
                  : 0,
              backgroundColor: Colors.grey.shade200,
              color: planColors[user.plan],
            ),
            const SizedBox(height: 4),
            Text(
              '${user.animalesCount} / ${user.limiteAnimales} animales',
              style: theme.textTheme.bodySmall,
            ),
            if (user.plan == 'gratuito') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showCambioPlan(context),
                  child: const Text('Mejorar Plan'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCambioPlan(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _CambioPlanSheet(ref: ref),
    );
  }
}

class _CambioPlanSheet extends StatelessWidget {
  final WidgetRef ref;
  const _CambioPlanSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Elige tu plan', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.blue),
            title: const Text('Básico - S/ 7.90/mes'),
            subtitle: const Text('150 animales, 3 generaciones'),
            onTap: () => _cambiar(context, 'basico'),
          ),
          ListTile(
            leading: const Icon(Icons.star, color: AppTheme.accent),
            title: const Text('Criador - S/ 19.90/mes'),
            subtitle: const Text('500 animales, 3 gen, reportes'),
            onTap: () => _cambiar(context, 'criador'),
          ),
        ],
      ),
    );
  }

  Future<void> _cambiar(BuildContext context, String plan) async {
    final error = await ref.read(authProvider.notifier).cambiarPlan(plan);
    if (context.mounted) Navigator.pop(context);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _InfoCard extends StatelessWidget {
  final UserModel user;
  const _InfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Información',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 12),
            _InfoRow(label: 'Generaciones árbol', value: '${user.generationsAllowed}'),
            _InfoRow(label: 'Miembro desde', value: user.createdAt != null
                ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                : '—'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
        ],
      ),
    );
  }
}
