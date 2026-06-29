import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front_genapp/data/services/api_service.dart';
import 'package:front_genapp/ui/core/theme.dart';

class ConsanguinidadScreen extends ConsumerStatefulWidget {
  const ConsanguinidadScreen({super.key});

  @override
  ConsumerState<ConsanguinidadScreen> createState() =>
      _ConsanguinidadScreenState();
}

class _ConsanguinidadScreenState extends ConsumerState<ConsanguinidadScreen> {
  final _api = ApiService();
  List<dynamic> _animales = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getList('/consanguinidad/');
      setState(() => _animales = data);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _nivelLabel(double coef) {
    if (coef == 0.0) return 'Sin consanguinidad';
    if (coef < 0.05) return 'Baja';
    if (coef < 0.125) return 'Media';
    return 'Alta';
  }

  Color _nivelColor(double coef) {
    if (coef == 0.0) return Colors.green;
    if (coef < 0.05) return Colors.orange;
    if (coef < 0.125) return Colors.deepOrange;
    return Colors.red;
  }

  void _showDetail(Map<String, dynamic> a) {
    final uid = a['uid'] as String? ?? '';
    final coef = (a['coeficiente'] as num?)?.toDouble() ?? 0.0;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.account_tree, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text('Consanguinidad',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow(Icons.label, 'Arete', a['arete'] ?? ''),
                    if ((a['nombre'] as String? ?? '').isNotEmpty)
                      const Divider(),
                    if ((a['nombre'] as String? ?? '').isNotEmpty)
                      _infoRow(Icons.pets, 'Nombre', a['nombre'] as String? ?? ''),
                    const Divider(),
                    _infoRow(Icons.category, 'Especie', a['especie'] ?? ''),
                    const Divider(),
                    _infoRow(Icons.calculate, 'Coeficiente',
                        '${(coef * 100).toStringAsFixed(2)}%'),
                    const Divider(),
                    _infoRow(Icons.info_outline, 'Nivel',
                        _nivelLabel(coef)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/animales/$uid/arbol');
                },
                icon: const Icon(Icons.account_tree),
                label: const Text('Ver Árbol Genealógico'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consanguinidad')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _animales.isEmpty
                ? const Center(
                    child: Text('No hay animales con padre y madre registrados'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _animales.length,
                    itemBuilder: (_, i) {
                      final a = _animales[i] as Map<String, dynamic>;
                      final uid = a['uid'] as String? ?? '';
                      final coef =
                          (a['coeficiente'] as num?)?.toDouble() ?? 0.0;
                      final color = _nivelColor(coef);
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.2),
                            child: Text(
                              '${(coef * 100).toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          title: Text('${a['arete']} - ${a['nombre'] ?? ''}'),
                          subtitle: Text(
                              '${_nivelLabel(coef)} (${a['especie']})'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.account_tree,
                                    size: 20),
                                onPressed: () =>
                                    context.push('/animales/$uid/arbol'),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'detail') _showDetail(a);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'detail',
                                    child: Text('Ver detalle'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => _showDetail(a),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
