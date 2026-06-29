import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_genapp/data/services/api_service.dart';
import 'package:front_genapp/ui/core/theme.dart';
import 'package:front_genapp/data/models/animal_model.dart';

class FibraRankingScreen extends ConsumerStatefulWidget {
  const FibraRankingScreen({super.key});

  @override
  ConsumerState<FibraRankingScreen> createState() => _FibraRankingScreenState();
}

class _FibraRankingScreenState extends ConsumerState<FibraRankingScreen> {
  final _api = ApiService();
  List<dynamic> _ranking = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getList('/ranking-fibra/');
      setState(() => _ranking = data);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ranking de Fibra')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _ranking.isEmpty
                ? const Center(child: Text('No hay datos de fibra registrados'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ranking.length,
                    itemBuilder: (_, i) {
                      final r = _ranking[i] as Map<String, dynamic>;
                      final micras = (r['diametro_fibra_micras'] as num?)?.toDouble();
                      final confort = (r['factor_confort'] as num?)?.toDouble();
                      final rend = (r['rendimiento_pct'] as num?)?.toDouble();

                      Color micrasColor;
                      if (micras == null) {
                        micrasColor = Colors.grey;
                      } else if (micras < 22) {
                        micrasColor = Colors.green;
                      } else if (micras < 26) {
                        micrasColor = Colors.orange;
                      } else {
                        micrasColor = Colors.red;
                      }

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.2),
                                child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${r['arete']} - ${r['nombre'] ?? ''}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(categoriaEdadLabel(r['categoria_edad'] as String?)),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        _Chip('${micras?.toStringAsFixed(1) ?? '-'} µ', micrasColor),
                                        if (confort != null)
                                          _Chip('${confort.toStringAsFixed(1)}% conf.', Colors.blue),
                                        if (rend != null)
                                          _Chip('${rend.toStringAsFixed(1)}% rend.', Colors.teal),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
