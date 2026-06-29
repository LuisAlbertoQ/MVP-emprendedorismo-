import 'package:flutter/material.dart';
import 'package:front_genapp/data/models/animal_model.dart' show CandidatoModel, categoriaEdadLabel;
import 'package:front_genapp/ui/core/theme.dart';

class AnimalSelector extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? errorText;
  final List<CandidatoModel> candidatos;
  final CandidatoModel? selected;
  final bool loading;
  final ValueChanged<CandidatoModel?> onSelected;

  const AnimalSelector({
    super.key,
    required this.label,
    required this.icon,
    this.errorText,
    required this.candidatos,
    required this.selected,
    this.loading = false,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showSearch(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          errorText: errorText,
          suffixIcon: selected != null
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => onSelected(null),
                )
              : null,
        ),
        child: Text(
          selected?.label ?? (loading ? 'Cargando...' : 'Toca para buscar'),
          style: TextStyle(color: selected != null ? null : Colors.grey),
        ),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    final filtered = ValueNotifier<List<CandidatoModel>>(candidatos);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AnimalSearchSheet(
        label: label,
        candidatos: candidatos,
        filtered: filtered,
        onSelected: (c) {
          onSelected(c);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _AnimalSearchSheet extends StatefulWidget {
  final String label;
  final List<CandidatoModel> candidatos;
  final ValueNotifier<List<CandidatoModel>> filtered;
  final ValueChanged<CandidatoModel> onSelected;

  const _AnimalSearchSheet({
    required this.label,
    required this.candidatos,
    required this.filtered,
    required this.onSelected,
  });

  @override
  State<_AnimalSearchSheet> createState() => _AnimalSearchSheetState();
}

class _AnimalSearchSheetState extends State<_AnimalSearchSheet> {
  final _searchCtrl = TextEditingController();
  String? _especieFiltro;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CandidatoModel> get _baseList {
    var list = widget.candidatos;
    if (_especieFiltro != null) {
      list = list.where((c) => c.especie == _especieFiltro).toList();
    }
    return list;
  }

  void _filter(String query) {
    final base = _baseList;
    if (query.isEmpty) {
      widget.filtered.value = base;
      return;
    }
    final lower = query.toLowerCase();
    widget.filtered.value = base.where((c) {
      return c.arete.toLowerCase().contains(lower) ||
          c.nombre.toLowerCase().contains(lower);
    }).toList();
  }

  void _setEspecie(String? especie) {
    setState(() => _especieFiltro = especie);
    _filter(_searchCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Buscar ${widget.label}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Buscar por arete o nombre...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _filter,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _EspecieChip(
                    label: 'Todas',
                    selected: _especieFiltro == null,
                    onTap: () => _setEspecie(null),
                  ),
                  const SizedBox(width: 6),
                  _EspecieChip(
                    label: 'Alpaca',
                    selected: _especieFiltro == 'alpaca',
                    onTap: () => _setEspecie('alpaca'),
                  ),
                  const SizedBox(width: 6),
                  _EspecieChip(
                    label: 'Llama',
                    selected: _especieFiltro == 'llama',
                    onTap: () => _setEspecie('llama'),
                  ),
                  const SizedBox(width: 6),
                  _EspecieChip(
                    label: 'Ovino',
                    selected: _especieFiltro == 'ovino',
                    onTap: () => _setEspecie('ovino'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ValueListenableBuilder<List<CandidatoModel>>(
                  valueListenable: widget.filtered,
                  builder: (_, list, __) {
                    if (list.isEmpty) {
                      return const Center(child: Text('Sin resultados'));
                    }
                    return ListView.separated(
                      controller: scrollCtrl,
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = list[i];
                        final especie = c.especie == 'alpaca'
                            ? 'Alpaca'
                            : c.especie == 'llama'
                                ? 'Llama'
                                : 'Ovino';
                        final sexo = c.sexo == 'macho' ? 'Macho' : 'Hembra';
                        final cat = categoriaEdadLabel(c.categoriaEdad);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: c.sexo == 'macho'
                                ? Colors.blue.shade100
                                : Colors.pink.shade100,
                            child: Icon(
                              c.sexo == 'macho'
                                  ? Icons.male
                                  : Icons.female,
                              color: c.sexo == 'macho'
                                  ? Colors.blue.shade700
                                  : Colors.pink.shade700,
                            ),
                          ),
                          title: Text(c.label),
                          subtitle: Text('$especie • $sexo • $cat'),
                          onTap: () => widget.onSelected(c),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EspecieChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _EspecieChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppTheme.primaryLight.withValues(alpha: 0.25),
      visualDensity: VisualDensity.compact,
    );
  }
}
