import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:front_genapp/data/models/animal_model.dart';
import 'package:front_genapp/ui/core/constants.dart';
import 'package:front_genapp/ui/core/theme.dart';
import 'package:front_genapp/ui/features/animales/providers/animal_provider.dart';

class AnimalDetailScreen extends ConsumerWidget {
  final String uid;
  const AnimalDetailScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(animalDetailProvider(uid));
    return Scaffold(
      body: async.when(
        data: (a) => _DetailBody(animal: a),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final AnimalModel animal;
  const _DetailBody({required this.animal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd/MM/yyyy').format(animal.fechaNacimiento);
    return CustomScrollView(
      slivers: [
        _Header(animal: animal, dateStr: dateStr),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _InfoSection(animal: animal, theme: theme),
              const SizedBox(height: 16),
              _ParentsSection(animal: animal),
              if (animal.observaciones.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ObservationsCard(
                    observaciones: animal.observaciones, theme: theme),
              ],
              const SizedBox(height: 24),
              _ActionButtons(animal: animal),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final AnimalModel animal;
  final String dateStr;
  const _Header({required this.animal, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    final isMale = animal.sexo == 'macho';
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: isMale
          ? Colors.blue.shade700
          : Colors.pink.shade700,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isMale ? Colors.blue.shade800 : Colors.pink.shade800,
                isMale ? Colors.blue.shade400 : Colors.pink.shade400,
                AppTheme.primary,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SpinnerNoOp(),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: Icon(
                  isMale ? Icons.male : Icons.female,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                animal.nombre.isNotEmpty
                    ? '${animal.arete} - ${animal.nombre}'
                    : animal.arete,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${animal.especie} • $dateStr',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_tree),
          tooltip: 'Árbol genealógico',
          onPressed: () => context.push(AppRoutes.animalArbol(animal.uid)),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => context.push(AppRoutes.animalEditar(animal.uid)),
        ),
      ],
    );
  }
}

class SpinnerNoOp extends StatelessWidget {
  const SpinnerNoOp({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _InfoSection extends StatelessWidget {
  final AnimalModel animal;
  final ThemeData theme;
  const _InfoSection({required this.animal, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Información General',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            _InfoRow(
              icon: Icons.label,
              label: 'Arete',
              value: animal.arete,
            ),
            _InfoRow(
              icon: Icons.pets,
              label: 'Especie',
              value: _capitalize(animal.especie),
            ),
            _InfoRow(
              icon: animal.sexo == 'macho' ? Icons.male : Icons.female,
              label: 'Sexo',
              value: animal.sexo == 'macho' ? 'Macho' : 'Hembra',
            ),
            _InfoRow(
              icon: Icons.category,
              label: 'Raza',
              value: animal.raza.isNotEmpty ? animal.raza : '—',
            ),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Nacimiento',
              value: DateFormat('dd/MM/yyyy').format(animal.fechaNacimiento),
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
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ParentsSection extends StatelessWidget {
  final AnimalModel animal;
  const _ParentsSection({required this.animal});

  @override
  Widget build(BuildContext context) {
    if (animal.padre == null && animal.madre == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.account_tree, color: Colors.grey.shade400),
              const SizedBox(width: 12),
              Text('Sin padres registrados',
                  style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }
    return Row(
      children: [
        if (animal.padre != null)
          Expanded(
            child: _ParentCard(
              label: 'Padre',
              name: animal.padre!,
              icon: Icons.male,
              color: Colors.blue,
              uid: animal.padreUid,
            ),
          ),
        if (animal.padre != null && animal.madre != null)
          const SizedBox(width: 8),
        if (animal.madre != null)
          Expanded(
            child: _ParentCard(
              label: 'Madre',
              name: animal.madre!,
              icon: Icons.female,
              color: Colors.pink,
              uid: animal.madreUid,
            ),
          ),
      ],
    );
  }
}

class _ParentCard extends StatelessWidget {
  final String label;
  final String name;
  final IconData icon;
  final Color color;
  final String? uid;

  const _ParentCard({
    required this.label,
    required this.name,
    required this.icon,
    required this.color,
    this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: uid != null
            ? () => context.push(AppRoutes.animalDetalle(uid!))
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.grey)),
              const SizedBox(height: 2),
              Text(name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ObservationsCard extends StatelessWidget {
  final String observaciones;
  final ThemeData theme;
  const _ObservationsCard(
      {required this.observaciones, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes, size: 20, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                Text('Observaciones',
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800)),
              ],
            ),
            const SizedBox(height: 8),
            Text(observaciones),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final AnimalModel animal;
  const _ActionButtons({required this.animal});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                context.push(AppRoutes.animalArbol(animal.uid)),
            icon: const Icon(Icons.account_tree),
            label: const Text('Árbol'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                context.push(AppRoutes.animalEditar(animal.uid)),
            icon: const Icon(Icons.edit),
            label: const Text('Editar'),
          ),
        ),
      ],
    );
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
