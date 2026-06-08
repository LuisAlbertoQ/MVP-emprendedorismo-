import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_genapp/data/models/animal_model.dart';
import 'package:front_genapp/ui/features/animales/providers/animal_provider.dart';

class ArbolScreen extends ConsumerWidget {
  final String uid;
  const ArbolScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(animalArbolProvider(uid));
    return Scaffold(
      appBar: AppBar(title: const Text('Árbol Genealógico')),
      body: async.when(
        data: (node) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _ArbolNodeWidget(
            node: node,
            depth: 0,
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ArbolNodeWidget extends StatelessWidget {
  final ArbolNode node;
  final int depth;

  const _ArbolNodeWidget({required this.node, required this.depth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: depth == 0
                ? Colors.green.shade100
                : depth == 1
                    ? Colors.blue.shade50
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: depth == 0
                  ? Colors.green
                  : depth == 1
                      ? Colors.blue.shade300
                      : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Text(
                node.nombre.isNotEmpty
                    ? '${node.arete} - ${node.nombre}'
                    : node.arete,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${node.especie} • ${node.sexo}',
                style: theme.textTheme.bodySmall,
              ),
              if (node.fechaNacimiento != null)
                Text(
                  '${node.fechaNacimiento!.day}/${node.fechaNacimiento!.month}/${node.fechaNacimiento!.year}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        if (node.padre != null || node.madre != null) ...[
          const SizedBox(height: 8),
          Icon(Icons.arrow_downward, size: 20, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Row(
            children: [
              if (node.padre != null)
                Expanded(
                  child: Column(
                    children: [
                      Text('Padre',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.blue.shade700,
                          )),
                      const SizedBox(height: 4),
                      _ArbolNodeWidget(
                        node: node.padre!,
                        depth: depth + 1,
                      ),
                    ],
                  ),
                ),
              if (node.padre != null && node.madre != null)
                const SizedBox(width: 8),
              if (node.madre != null)
                Expanded(
                  child: Column(
                    children: [
                      Text('Madre',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.pink.shade700,
                          )),
                      const SizedBox(height: 4),
                      _ArbolNodeWidget(
                        node: node.madre!,
                        depth: depth + 1,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
