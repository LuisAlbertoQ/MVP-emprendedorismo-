import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front_genapp/data/services/api_service.dart';
import 'package:front_genapp/ui/core/constants.dart';
import 'package:front_genapp/ui/core/theme.dart';

class CostoListScreen extends ConsumerStatefulWidget {
  const CostoListScreen({super.key});

  @override
  ConsumerState<CostoListScreen> createState() => _CostoListScreenState();
}

class _CostoListScreenState extends ConsumerState<CostoListScreen> {
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
      final data = await _api.getList('/costos/');
      setState(() => _list = data);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(String uid) async {
    try {
      await _api.delete('/costos/$uid/');
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar')));
    }
  }

  IconData _tipoIcon(String tipo) {
    switch (tipo) {
      case 'alimentacion': return Icons.restaurant;
      case 'sanidad': return Icons.medical_services;
      case 'esquila': return Icons.content_cut;
      case 'transporte': return Icons.local_shipping;
      default: return Icons.receipt;
    }
  }

  String _fmt(String? d) => d != null ? d.split('T')[0] : '—';

  String tipoCostoLabel(String t) {
    switch (t) {
      case 'alimentacion': return 'Alimentación';
      case 'sanidad': return 'Sanidad';
      case 'esquila': return 'Esquila';
      case 'transporte': return 'Transporte';
      default: return 'Otro';
    }
  }

  void _showDetail(Map<String, dynamic> c) {
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
                Icon(Icons.receipt, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text('Detalle de Costo',
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
                    _infoRow(Icons.pets, 'Animal', c['animal_arete'] ?? '—'),
                    const Divider(),
                    _infoRow(Icons.category, 'Tipo',
                        tipoCostoLabel(c['tipo'] as String? ?? '')),
                    const Divider(),
                    _infoRow(Icons.attach_money, 'Monto',
                        'S/${double.tryParse(c['monto']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}'),
                    const Divider(),
                    _infoRow(Icons.calendar_today, 'Fecha',
                        _fmt(c['fecha'] as String?)),
                    if ((c['descripcion'] as String? ?? '').isNotEmpty) ...[
                      const Divider(),
                      _infoRow(Icons.description, 'Descripción',
                          c['descripcion'] as String? ?? ''),
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
    final total = _list.fold<double>(0, (s, c) {
      final m = (c as Map<String, dynamic>)['monto'];
      return s + (double.tryParse(m?.toString() ?? '0') ?? 0);
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Costos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push(AppRoutes.costosCrear);
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? const Center(child: Text('No hay costos registrados'))
                : Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.green.shade50,
                        child: Text(
                          'Total: S/${total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _list.length,
                          itemBuilder: (_, i) {
                            final c = _list[i] as Map<String, dynamic>;
                            final uid = c['uid'] as String? ?? '';
                            final monto = double.tryParse(c['monto']?.toString() ?? '0') ?? 0;
                            return Card(
                              child: ListTile(
                                onTap: () => _showDetail(c),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.amber.withValues(alpha: 0.2),
                                  child: Icon(_tipoIcon(c['tipo'] as String? ?? ''), color: Colors.amber.shade800),
                                ),
                                title: Text('${c['animal_arete'] ?? ''} · ${tipoCostoLabel(c['tipo'] as String? ?? '')}'),
                                subtitle: Text((c['fecha'] as String? ?? '').split('T')[0]),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('S/${monto.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(width: 4),
                                    PopupMenuButton<String>(
                                      onSelected: (v) async {
                                        if (v == 'edit') {
                                          await context.push('/gestion/costos/$uid/editar');
                                          _load();
                                        } else if (v == 'delete') {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Eliminar costo'),
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
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
