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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _Header(user: user),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                _PlanCard(user: user),
                const SizedBox(height: 16),
                _InfoCard(user: user),
                const SizedBox(height: 16),
                _LogoutButton(),
                const SizedBox(height: 32),
              ]),
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
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryDark,
                AppTheme.primary,
                AppTheme.primaryLight,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: const Icon(
                  Icons.person,
                  size: 46,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                user.firstName.isNotEmpty ? user.firstName : user.telefono,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user.telefono,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final UserModel user;
  const _PlanCard({required this.user});

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
    final color = planColors[user.plan] ?? Colors.grey;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.workspace_premium, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan ${planLabels[user.plan] ?? user.plan}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${user.animalesCount} de ${user.limiteAnimales} animales',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    planLabels[user.plan] ?? user.plan,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: user.limiteAnimales > 0
                    ? (user.animalesCount / user.limiteAnimales).clamp(0.0, 1.0)
                    : 0,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: color,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCambioPlan(context),
                icon: Icon(
                  Icons.swap_horiz,
                  color: color,
                ),
                label: Text(
                  user.plan == 'gratuito' ? 'Mejorar Plan' : 'Cambiar Plan',
                  style: TextStyle(color: color),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCambioPlan(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => const _CambioPlanSheet(),
    );
  }
}

class _CambioPlanSheet extends ConsumerWidget {
  const _CambioPlanSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPlan = ref.watch(authProvider).user?.plan ?? 'gratuito';
    final plans = [
      _PlanOption(
        value: 'gratuito',
        title: 'Gratuito',
        subtitle: '20 animales, 2 generaciones',
        icon: Icons.free_breakfast,
        color: Colors.grey,
      ),
      _PlanOption(
        value: 'basico',
        title: 'Básico - S/ 7.90/mes',
        subtitle: '150 animales, 3 generaciones',
        icon: Icons.star,
        color: Colors.blue,
      ),
      _PlanOption(
        value: 'criador',
        title: 'Criador - S/ 19.90/mes',
        subtitle: '500 animales, 3 gen, reportes',
        icon: Icons.star,
        color: AppTheme.accent,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Elige tu plan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 16),
          ...plans.map((p) {
            final isCurrent = p.value == currentPlan;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: isCurrent ? null : () => _cambiar(context, ref, p.value),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent ? p.color : Colors.grey.shade300,
                      width: isCurrent ? 2 : 1,
                    ),
                    color: isCurrent
                        ? p.color.withValues(alpha: 0.08)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(p.icon, color: p.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.title,
                              style: TextStyle(
                                fontWeight:
                                    isCurrent ? FontWeight.w600 : FontWeight.w400,
                                color: isCurrent ? p.color : Colors.black87,
                              ),
                            ),
                            Text(
                              p.subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrent) Icon(Icons.check_circle, color: p.color),
                      if (!isCurrent)
                        Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _cambiar(
      BuildContext context, WidgetRef ref, String plan) async {
    final error = await ref.read(authProvider.notifier).cambiarPlan(plan);
    if (context.mounted) Navigator.pop(context);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _PlanOption {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _PlanOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _InfoCard extends StatelessWidget {
  final UserModel user;
  const _InfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline,
                      color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Información',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.account_tree,
              label: 'Generaciones árbol',
              value: '${user.generationsAllowed}',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Miembro desde',
              value: user.createdAt != null
                  ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                  : '—',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey.shade600)),
        const Spacer(),
        Text(value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
      ],
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => ref.read(authProvider.notifier).logout(),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Cerrar Sesión'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade400,
          side: BorderSide(color: Colors.red.shade200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
