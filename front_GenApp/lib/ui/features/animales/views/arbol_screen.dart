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
          child: _ArbolNodeWidget(node: node, depth: 0),
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
    final indent = 24.0 * depth;

    final bgColor = depth == 0
        ? Colors.green.shade100
        : depth == 1
            ? Colors.blue.shade50
            : Colors.grey.shade100;
    final borderColor = depth == 0
        ? Colors.green
        : depth == 1
            ? Colors.blue.shade300
            : Colors.grey.shade300;

    final children = <Widget>[
      Padding(
        padding: EdgeInsets.only(left: indent),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                node.nombre.isNotEmpty
                    ? '${node.arete} - ${node.nombre}'
                    : node.arete,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_especieLabel(node.especie)} • ${_sexoLabel(node.sexo)}',
                style: theme.textTheme.bodySmall,
              ),
              if (node.fechaNacimiento != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${node.fechaNacimiento!.day}/${node.fechaNacimiento!.month}/${node.fechaNacimiento!.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ];

    if (node.padre != null) {
      children.add(_ParentSection(
        indent: indent,
        label: 'Padre',
        labelColor: Colors.blue.shade700,
        lineColor: Colors.blue.shade300,
        child: _ArbolNodeWidget(node: node.padre!, depth: depth + 1),
      ));
    }

    if (node.madre != null) {
      children.add(_ParentSection(
        indent: indent,
        label: 'Madre',
        labelColor: Colors.pink.shade700,
        lineColor: Colors.pink.shade300,
        child: _ArbolNodeWidget(node: node.madre!, depth: depth + 1),
      ));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  String _especieLabel(String e) {
    switch (e) {
      case 'alpaca':
        return 'Alpaca';
      case 'llama':
        return 'Llama';
      case 'ovino':
        return 'Ovino';
      default:
        return e;
    }
  }

  String _sexoLabel(String s) => s == 'macho' ? 'Macho' : 'Hembra';
}

class _ParentSection extends StatelessWidget {
  final double indent;
  final String label;
  final Color labelColor;
  final Color lineColor;
  final Widget child;

  const _ParentSection({
    required this.indent,
    required this.label,
    required this.labelColor,
    required this.lineColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: indent + 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              _ConnectorLine(lineColor: lineColor),
              const SizedBox(width: 10),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ConnectorLine extends StatelessWidget {
  final Color lineColor;
  const _ConnectorLine({required this.lineColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      child: Column(
        children: [
          Container(width: 14, height: 2, color: lineColor),
          const SizedBox(height: 3),
          Container(width: 2, height: 16, color: lineColor),
        ],
      ),
    );
  }
}
