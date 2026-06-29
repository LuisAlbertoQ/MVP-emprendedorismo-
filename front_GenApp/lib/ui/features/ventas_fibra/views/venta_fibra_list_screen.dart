import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front_genapp/data/services/api_service.dart';
import 'package:front_genapp/ui/core/constants.dart';
import 'package:front_genapp/ui/core/theme.dart';

class VentaFibraListScreen extends ConsumerStatefulWidget {
  const VentaFibraListScreen({super.key});

  @override
  ConsumerState<VentaFibraListScreen> createState() => _VentaFibraListScreenState();
}

class _VentaFibraListScreenState extends ConsumerState<VentaFibraListScreen> {
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
      final data = await _api.getList('/ventas-fibra/');
      setState(() => _list = data);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(String uid) async {
    try {
      await _api.delete('/ventas-fibra/$uid/');
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar')));
    }
  }

  double _ingreso(Map<String, dynamic> v) {
    final total = v['ingreso_total'];
    if (total != null) return double.tryParse(total.toString()) ?? 0;
    final kg = double.tryParse(v['kg_vendidos']?.toString() ?? '0') ?? 0;
    final precio = double.tryParse(v['precio_kg']?.toString() ?? '0') ?? 0;
    return kg * precio;
  }

  String _fmt(String? d) => d != null ? d.split('T')[0] : '—';

  void _showDetail(Map<String, dynamic> v) {
    final ingreso = _ingreso(v);
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
                Icon(Icons.sell, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text('Detalle de Venta',
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
                    _infoRow(Icons.pets, 'Animal', v['animal_arete'] ?? '—'),
                    const Divider(),
                    _infoRow(Icons.monitor_weight, 'Kg Vendidos',
                        '${v['kg_vendidos'] ?? '0'} kg'),
                    const Divider(),
                    _infoRow(Icons.attach_money, 'Precio/kg',
                        'S/${v['precio_kg'] ?? '0.00'}'),
                    const Divider(),
                    _infoRow(Icons.account_balance_wallet, 'Ingreso',
                        'S/${ingreso.toStringAsFixed(2)}'),
                    const Divider(),
                    _infoRow(Icons.calendar_today, 'Fecha Venta',
                        _fmt(v['fecha_venta'] as String?)),
                    if ((v['comprador'] as String? ?? '').isNotEmpty) ...[
                      const Divider(),
                      _infoRow(Icons.person, 'Comprador',
                          v['comprador'] as String? ?? ''),
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
    final totalIngresos = _list.fold<double>(0, (s, v) => s + _ingreso(v as Map<String, dynamic>));
    return Scaffold(
      appBar: AppBar(title: const Text('Ventas de Fibra')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push(AppRoutes.ventasFibraCrear);
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? const Center(child: Text('No hay ventas registradas'))
                : Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.green.shade50,
                        child: Text(
                          'Ingresos totales: S/${totalIngresos.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _list.length,
                          itemBuilder: (_, i) {
                            final v = _list[i] as Map<String, dynamic>;
                            final uid = v['uid'] as String? ?? '';
                            final ingreso = _ingreso(v);
                            return Card(
                              child: ListTile(
                                onTap: () => _showDetail(v),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.teal.withValues(alpha: 0.2),
                                  child: const Icon(Icons.sell, color: Colors.teal),
                                ),
                                title: Text(v['animal_arete'] as String? ?? ''),
                                subtitle: Text(
                                  '${(v['fecha_venta'] as String? ?? '').split('T')[0]}'
                                  ' · ${(v['comprador'] as String? ?? '').isNotEmpty ? v['comprador'] : '—'}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('S/${ingreso.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('${v['kg_vendidos'] ?? ''} kg',
                                          style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (v2) async {
                                        if (v2 == 'edit') {
                                          await context.push('/gestion/ventas-fibra/$uid/editar');
                                          _load();
                                        } else if (v2 == 'delete') {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Eliminar venta'),
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
