import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front_genapp/data/services/api_service.dart';
import 'package:front_genapp/ui/core/constants.dart';
import 'package:front_genapp/ui/core/theme.dart';

class PartoListScreen extends ConsumerStatefulWidget {
  const PartoListScreen({super.key});

  @override
  ConsumerState<PartoListScreen> createState() => _PartoListScreenState();
}

class _PartoListScreenState extends ConsumerState<PartoListScreen> {
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
      final data = await _api.getList('/partos/');
      setState(() => _list = data);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(String uid) async {
    try {
      await _api.delete('/partos/$uid/');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiService.extractError(e))));
      }
    }
  }

  String _fmt(String? d) => d != null ? d.split('T')[0] : '—';

  void _showDetail(Map<String, dynamic> p) {
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
                Icon(Icons.child_care, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text('Detalle de Parto',
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
                    _infoRow(Icons.female, 'Hembra', p['hembra_arete'] ?? '—'),
                    const Divider(),
                    _infoRow(Icons.calendar_today, 'Fecha Parto',
                        _fmt(p['fecha_parto'] as String?)),
                    const Divider(),
                    _infoRow(Icons.child_care, 'N° Crías',
                        '${p['numero_crias'] ?? 1}'),
                    if ((p['incidencias'] as String? ?? '').isNotEmpty) ...[
                      const Divider(),
                      _infoRow(Icons.warning_amber, 'Incidencias',
                          p['incidencias'] as String? ?? ''),
                    ],
                    if ((p['observaciones'] as String? ?? '').isNotEmpty) ...[
                      const Divider(),
                      _infoRow(Icons.notes, 'Obs.', p['observaciones'] as String? ?? ''),
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
      appBar: AppBar(title: const Text('Partos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push(AppRoutes.partosCrear);
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? const Center(child: Text('No hay partos registrados'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final p = _list[i] as Map<String, dynamic>;
                      final uid = p['uid'] as String? ?? '';
                      final nc = p['numero_crias'] as int? ?? 1;
                      final inc = p['incidencias'] as String? ?? '';
                      return Card(
                        child: ListTile(
                          onTap: () => _showDetail(p),
                          leading: CircleAvatar(
                            backgroundColor: Colors.pink.withValues(alpha: 0.2),
                            child: Text('$nc', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          title: Text(p['hembra_arete'] as String? ?? ''),
                          subtitle: Text(
                            '${_fmt(p['fecha_parto'] as String?)} · $nc cría${nc != 1 ? 's' : ''}'
                            '${inc.isNotEmpty ? ' · $inc' : ''}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'edit') {
                                await context.push('/gestion/partos/$uid/editar');
                                _load();
                              } else if (v == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Eliminar parto'),
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
