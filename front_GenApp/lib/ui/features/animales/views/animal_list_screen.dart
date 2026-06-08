import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:front_genapp/data/models/animal_model.dart';
import 'package:front_genapp/ui/core/constants.dart';
import 'package:front_genapp/ui/features/animales/providers/animal_provider.dart';

class AnimalListScreen extends ConsumerStatefulWidget {
  const AnimalListScreen({super.key});

  @override
  ConsumerState<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends ConsumerState<AnimalListScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(animalListProvider.notifier).loadAnimales(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showFiltros,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.animalesCrear),
        child: const Icon(Icons.add),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(AnimalListState state) {
    if (state.isLoading && state.animales.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.animales.isEmpty) {
      return const Center(child: Text(AppStrings.noHayAnimales));
    }
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(animalListProvider.notifier).loadAnimales(refresh: true);
      },
      child: ListView.builder(
        controller: _scrollCtrl,
        itemCount: state.animales.length + (state.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= state.animales.length) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ));
          }
          return _AnimalTile(animal: state.animales[i]);
        },
      ),
    );
  }

  void _showFiltros() {
    showModalBottomSheet(
      context: context,
      builder: (_) => _FiltrosSheet(
        onApply: (especie, sexo) {
          ref.read(animalListProvider.notifier).setFiltros(
                especie: especie,
                sexo: sexo,
              );
        },
      ),
    );
  }
}

class _AnimalTile extends StatelessWidget {
  final AnimalListModel animal;
  const _AnimalTile({required this.animal});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('dd/MM/yyyy').format(animal.fechaNacimiento);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: animal.sexo == 'macho'
              ? Colors.blue.shade100
              : Colors.pink.shade100,
          child: Icon(
            animal.sexo == 'macho' ? Icons.male : Icons.female,
            color: animal.sexo == 'macho'
                ? Colors.blue.shade700
                : Colors.pink.shade700,
          ),
        ),
        title: Text(animal.nombre.isNotEmpty
            ? '${animal.arete} - ${animal.nombre}'
            : animal.arete),
        subtitle: Text(
          '${animal.especie} • $dateStr',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            context.push(AppRoutes.animalDetalle(animal.uid)),
      ),
    );
  }
}

class _FiltrosSheet extends StatefulWidget {
  final void Function(String? especie, String? sexo) onApply;
  const _FiltrosSheet({required this.onApply});

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  String? _especie;
  String? _sexo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtrar', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _especie,
            decoration: const InputDecoration(labelText: 'Especie'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todas')),
              DropdownMenuItem(value: 'alpaca', child: Text('Alpaca')),
              DropdownMenuItem(value: 'llama', child: Text('Llama')),
              DropdownMenuItem(value: 'ovino', child: Text('Ovino')),
            ],
            onChanged: (v) => setState(() => _especie = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _sexo,
            decoration: const InputDecoration(labelText: 'Sexo'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'macho', child: Text('Macho')),
              DropdownMenuItem(value: 'hembra', child: Text('Hembra')),
            ],
            onChanged: (v) => setState(() => _sexo = v),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_especie, _sexo);
                Navigator.pop(context);
              },
              child: const Text('Aplicar'),
            ),
          ),
        ],
      ),
    );
  }
}
