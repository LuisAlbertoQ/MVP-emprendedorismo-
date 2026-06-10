import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:front_genapp/data/models/animal_model.dart' show AnimalListModel, categoriaEdadLabel;
import 'package:front_genapp/ui/core/constants.dart';
import 'package:front_genapp/ui/core/theme.dart';
import 'package:front_genapp/ui/features/animales/providers/animal_provider.dart';

class AnimalListScreen extends ConsumerStatefulWidget {
  const AnimalListScreen({super.key});

  @override
  ConsumerState<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends ConsumerState<AnimalListScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final s = ref.read(animalListProvider).search;
      if (s.isNotEmpty) _searchCtrl.text = s;
      ref.read(animalListProvider.notifier).loadAnimales(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(animalListProvider.notifier).setSearch(value);
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients || _scrollCtrl.position.maxScrollExtent <= 0) {
      return;
    }
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(animalListProvider.notifier).loadAnimales();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(animalListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Animales'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.animalesCrear),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por arete o nombre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref
                              .read(animalListProvider.notifier)
                              .setSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          _FiltrosChips(
            especie: state.filtroEspecie,
            sexo: state.filtroSexo,
            onChanged: (especie, sexo) {
              ref.read(animalListProvider.notifier).setFiltros(
                    especie: especie,
                    sexo: sexo,
                  );
            },
          ),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(AnimalListState state) {
    if (state.isLoading && state.animales.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.animales.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              state.search.isNotEmpty
                  ? 'Sin resultados para "${state.search}"'
                  : state.filtroEspecie != null || state.filtroSexo != null
                      ? 'Sin resultados con esos filtros'
                      : AppStrings.noHayAnimales,
              style: TextStyle(color: Colors.grey.shade500),
            ),
            if (state.filtroEspecie != null ||
                state.filtroSexo != null ||
                state.search.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchCtrl.clear();
                  ref
                      .read(animalListProvider.notifier)
                      .setFiltros(especie: null, sexo: null);
                },
                child: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(animalListProvider.notifier).loadAnimales(refresh: true);
      },
      child: ListView.builder(
        controller: _scrollCtrl,
        itemCount: state.animales.length + (state.hasMore ? 1 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemBuilder: (_, i) {
          if (i >= state.animales.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _AnimalCard(animal: state.animales[i]);
        },
      ),
    );
  }
}

class _FiltrosChips extends StatelessWidget {
  final String? especie;
  final String? sexo;
  final void Function(String? especie, String? sexo) onChanged;

  const _FiltrosChips({
    required this.especie,
    required this.sexo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ChipFilter(
              label: especie != null
                  ? _especieLabel(especie!)
                  : 'Especie',
              selected: especie != null,
              icon: Icons.pets,
              onTap: () => _showEspecieSheet(context),
            ),
            const SizedBox(width: 8),
            _ChipFilter(
              label: sexo != null ? _sexoLabel(sexo!) : 'Sexo',
              selected: sexo != null,
              icon: sexo == 'macho'
                  ? Icons.male
                  : sexo == 'hembra'
                      ? Icons.female
                      : Icons.wc,
              onTap: () => _showSexoSheet(context),
            ),
            if (especie != null || sexo != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => onChanged(null, null),
                tooltip: 'Limpiar filtros',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEspecieSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _OptionSheet(
        title: 'Filtrar por especie',
        options: const [
          'Todas',
          'Alpaca',
          'Llama',
          'Ovino',
        ],
        values: const [null, 'alpaca', 'llama', 'ovino'],
        selected: especie,
        onSelected: (v) => onChanged(v as String?, sexo),
      ),
    );
  }

  void _showSexoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _OptionSheet(
        title: 'Filtrar por sexo',
        options: const ['Todos', 'Macho', 'Hembra'],
        values: const [null, 'macho', 'hembra'],
        selected: sexo,
        onSelected: (v) => onChanged(especie, v as String?),
      ),
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

class _ChipFilter extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _ChipFilter({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      avatar: Icon(icon, size: 16),
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppTheme.primaryLight.withValues(alpha: 0.25),
    );
  }
}

class _OptionSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final List<dynamic> values;
  final dynamic selected;
  final ValueChanged<dynamic> onSelected;

  const _OptionSheet({
    required this.title,
    required this.options,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...List.generate(options.length, (i) {
              final isSelected = values[i] == selected;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    onSelected(values[i]);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            options[i],
                            style: TextStyle(
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? AppTheme.primary
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AnimalCard extends ConsumerWidget {
  final AnimalListModel animal;
  const _AnimalCard({required this.animal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd/MM/yyyy').format(animal.fechaNacimiento);
    final isMale = animal.sexo == 'macho';

    return Dismissible(
      key: ValueKey(animal.uid),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar animal'),
            content: Text(
              '¿Eliminar "${animal.nombre.isNotEmpty ? '${animal.arete} - ${animal.nombre}' : animal.arete}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) async {
        try {
          await ref.read(animalRepositoryProvider).deleteAnimal(animal.uid);
          ref.read(animalListProvider.notifier).loadAnimales(refresh: true);
          ref.invalidate(resumenProvider);
        } catch (e) {
          ref.read(animalListProvider.notifier).loadAnimales(refresh: true);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al eliminar: $e')),
            );
          }
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade500,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.animalDetalle(animal.uid)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isMale
                        ? Colors.blue.shade50
                        : Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isMale ? Icons.male : Icons.female,
                    color: isMale ? Colors.blue : Colors.pink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal.nombre.isNotEmpty
                            ? '${animal.arete} - ${animal.nombre}'
                            : animal.arete,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _Tag(
                            text: _especieLabel(animal.especie),
                            color: AppTheme.primaryLight,
                          ),
                          const SizedBox(width: 6),
                          _Tag(
                            text: isMale ? 'Macho' : 'Hembra',
                            color: isMale ? Colors.blue : Colors.pink,
                          ),
                          const SizedBox(width: 6),
                          _Tag(
                            text: categoriaEdadLabel(animal.categoriaEdad),
                            color: Colors.teal,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateStr,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
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
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
