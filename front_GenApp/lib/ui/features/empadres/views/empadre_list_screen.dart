import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front_genapp/data/services/api_service.dart';
import 'package:front_genapp/ui/core/constants.dart';
import 'package:front_genapp/ui/core/theme.dart';

class EmpadreListScreen extends ConsumerStatefulWidget {
  const EmpadreListScreen({super.key});

  @override
  ConsumerState<EmpadreListScreen> createState() => _EmpadreListScreenState();
}

class _EmpadreListScreenState extends ConsumerState<EmpadreListScreen> {
  final _api = ApiService();
  List<dynamic> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getList('/empadres/');
      setState(() => _list = data);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(String uid) async {
    try {
      await _api.delete('/empadres/$uid/');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiService.extractError(e))));
      }
    }
  }

  Color _resultadoColor(String r) {
    switch (r) {
      case 'positivo': return Colors.green;
      case 'negativo': return Colors.red;
      case 'no_revisado': return Colors.grey;
      default: return Colors.orange;
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '—';
    return d.split('T')[0];
  }

  String resultadoGestacionLabel(String r) {
    switch (r) {
      case 'positivo': return 'Positivo';
      case 'negativo': return 'Negativo';
      case 'no_revisado': return 'No revisado';
      default: return 'Pendiente';
    }
  }

  void _showDetail(Map<String, dynamic> e) {
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
                Icon(Icons.favorite_border, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text('Detalle de Empadre',
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
                    _infoRow(Icons.female, 'Hembra', e['hembra_arete'] ?? '—'),
                    const Divider(),
                    _infoRow(Icons.male, 'Macho', e['macho_arete'] ?? '—'),
                    const Divider(),
                    _infoRow(Icons.calendar_today, 'Empadre',
                        _formatDate(e['fecha_empadre'] as String?)),
                    const Divider(),
                    _infoRow(Icons.favorite_border, 'Resultado',
                        resultadoGestacionLabel(e['resultado'] as String? ?? '')),
                    if (e['fecha_probable_parto'] != null) ...[
                      const Divider(),
                      _infoRow(Icons.child_care, 'Parto Prob.',
                          _formatDate(e['fecha_probable_parto'] as String?)),
                    ],
                    if ((e['observaciones'] as String? ?? '').isNotEmpty) ...[
                      const Divider(),
                      _infoRow(Icons.notes, 'Obs.', e['observaciones'] as String? ?? ''),
                    ],
                  ],
                ),
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
      appBar: AppBar(title: const Text('Empadres')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push(AppRoutes.empadresCrear);
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? const Center(child: Text('No hay empadres registrados'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final e = _list[i] as Map<String, dynamic>;
                      final uid = e['uid'] as String? ?? '';
                      final fechaProbable = e['fecha_probable_parto'] as String?;
                      return Card(
                          child: ListTile(
                            onTap: () => _showDetail(e),
                            leading: CircleAvatar(
                              backgroundColor: _resultadoColor(e['resultado'] as String? ?? '').withValues(alpha: 0.2),
                              child: Icon(Icons.favorite_border, color: _resultadoColor(e['resultado'] as String? ?? '')),
                            ),
                            title: Text('${e['hembra_arete'] ?? ''} x ${e['macho_arete'] ?? ''}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_formatDate(e['fecha_empadre'] as String?)} · ${resultadoGestacionLabel(e['resultado'] as String? ?? '')}'),
                                if (fechaProbable != null)
                                  Text('Parto probable: ${_formatDate(fechaProbable)}',
                                    style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                              ],
                            ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'edit') {
                                await context.push('/gestion/empadres/$uid/editar');
                                _load();
                              } else if (v == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Eliminar empadre'),
                                    content: const Text('¿Estás seguro?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                      TextButton(onPressed: () { Navigator.pop(ctx); _delete(uid); }, child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Text('Editar')),
                              const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
