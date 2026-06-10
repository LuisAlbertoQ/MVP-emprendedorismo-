import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:front_genapp/data/models/animal_model.dart';
import 'package:front_genapp/ui/core/constants.dart';
import 'package:front_genapp/ui/core/widgets/loading_button.dart';
import 'package:front_genapp/ui/features/animales/providers/animal_provider.dart';

class AnimalFormScreen extends ConsumerStatefulWidget {
  final String? uid;
  const AnimalFormScreen({super.key, this.uid});

  @override
  ConsumerState<AnimalFormScreen> createState() => _AnimalFormScreenState();
}

class _AnimalFormScreenState extends ConsumerState<AnimalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _areteCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _razaCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  String _especie = 'alpaca';
  String _sexo = 'macho';
  DateTime _fechaNac = DateTime.now();
  bool _saving = false;

  CandidatoModel? _padre;
  CandidatoModel? _madre;

  List<CandidatoModel> _candidatos = [];
  bool _loadingCandidatos = false;

  String? _fotoPath;
  final _picker = ImagePicker();
  Map<String, String> _fieldErrors = {};

  bool get _isEditing => widget.uid != null;

  @override
  void initState() {
    super.initState();
    _loadCandidatos();
    if (_isEditing) {
      Future.microtask(() => _loadAnimal());
    }
  }

  Future<void> _loadCandidatos() async {
    setState(() => _loadingCandidatos = true);
    try {
      final repo = ref.read(animalRepositoryProvider);
      _candidatos = await repo.getCandidatos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar candidatos: $e')),
        );
      }
    }
    if (mounted) setState(() => _loadingCandidatos = false);
  }

  Future<void> _loadAnimal() async {
    try {
      final animal =
          await ref.read(animalRepositoryProvider).getAnimal(widget.uid!);
      _areteCtrl.text = animal.arete;
      _nombreCtrl.text = animal.nombre;
      _razaCtrl.text = animal.raza;
      _obsCtrl.text = animal.observaciones;
      _especie = animal.especie;
      _sexo = animal.sexo;
      _fechaNac = animal.fechaNacimiento;
      if (animal.padreUid != null) {
        _padre =
            _candidatos.where((c) => c.uid == animal.padreUid).firstOrNull;
      }
      if (animal.madreUid != null) {
        _madre =
            _candidatos.where((c) => c.uid == animal.madreUid).firstOrNull;
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar animal: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _areteCtrl.dispose();
    _nombreCtrl.dispose();
    _razaCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNac,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fechaNac = picked);
  }

  Future<void> _pickFoto() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (xfile != null) setState(() => _fotoPath = xfile.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _fieldErrors = {};
    });
    try {
      final animal = AnimalModel(
        uid: '',
        arete: _areteCtrl.text.trim(),
        especie: _especie,
        sexo: _sexo,
        fechaNacimiento: _fechaNac,
        nombre: _nombreCtrl.text.trim(),
        raza: _razaCtrl.text.trim(),
        padreUid: _padre?.uid,
        madreUid: _madre?.uid,
        observaciones: _obsCtrl.text.trim(),
      );
      final repo = ref.read(animalRepositoryProvider);
      String uid;
      if (_isEditing) {
        await repo.updateAnimal(widget.uid!, animal);
        uid = widget.uid!;
      } else {
        final created = await repo.createAnimal(animal);
        uid = created.uid;
      }
      if (_fotoPath != null) {
        try {
          await repo.subirFoto(uid, _fotoPath!);
        } catch (_) {}
      }
      if (mounted) {
        ref.read(animalListProvider.notifier).loadAnimales(refresh: true);
        ref.invalidate(animalDetailProvider(uid));
        ref.invalidate(animalArbolProvider(uid));
        ref.invalidate(resumenProvider);
        context.pop();
      }
    } catch (e) {
      if (e is DioException && e.response?.data is Map) {
        final errors = e.response!.data as Map<String, dynamic>;
        setState(() {
          _fieldErrors = errors.map(
              (k, v) => MapEntry(k, v is List ? v.first.toString() : v.toString()));
        });
      }
      if (mounted && _fieldErrors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Animal' : AppStrings.criar),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _areteCtrl,
                decoration: InputDecoration(
                  labelText: 'Arete *',
                  prefixIcon: const Icon(Icons.tag),
                  errorText: _fieldErrors['arete'],
                ),
                validator: (v) =>
                    v != null && v.trim().isNotEmpty ? null : 'Requerido',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.pets),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _especie,
                decoration: const InputDecoration(labelText: 'Especie *'),
                items: const [
                  DropdownMenuItem(value: 'alpaca', child: Text('Alpaca')),
                  DropdownMenuItem(value: 'llama', child: Text('Llama')),
                  DropdownMenuItem(value: 'ovino', child: Text('Ovino')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _especie = v);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _sexo,
                decoration: const InputDecoration(labelText: 'Sexo *'),
                items: const [
                  DropdownMenuItem(value: 'macho', child: Text('Macho')),
                  DropdownMenuItem(value: 'hembra', child: Text('Hembra')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _sexo = v);
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de Nacimiento *',
                    prefixIcon: const Icon(Icons.calendar_today),
                    errorText: _fieldErrors['fecha_nacimiento'],
                  ),
                  child: Text(
                    '${_fechaNac.day}/${_fechaNac.month}/${_fechaNac.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _razaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Raza',
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 16),
              _ParentSelector(
                label: 'Padre',
                icon: Icons.male,
                errorText: _fieldErrors['padre'],
                candidatos: _candidatos,
                selected: _padre,
                loading: _loadingCandidatos,
                onSelected: (c) => setState(() => _padre = c),
              ),
              const SizedBox(height: 16),
              _ParentSelector(
                label: 'Madre',
                icon: Icons.female,
                errorText: _fieldErrors['madre'],
                candidatos: _candidatos,
                selected: _madre,
                loading: _loadingCandidatos,
                onSelected: (c) => setState(() => _madre = c),
              ),
              const SizedBox(height: 16),
              _FotoPicker(
                path: _fotoPath,
                onPick: _pickFoto,
                onClear: () => setState(() => _fotoPath = null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _obsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              LoadingButton(
                loading: _saving,
                label: AppStrings.guardar,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentSelector extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? errorText;
  final List<CandidatoModel> candidatos;
  final CandidatoModel? selected;
  final bool loading;
  final ValueChanged<CandidatoModel?> onSelected;

  const _ParentSelector({
    required this.label,
    required this.icon,
    this.errorText,
    required this.candidatos,
    required this.selected,
    required this.loading,
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
          style: TextStyle(
            color: selected != null ? null : Colors.grey,
          ),
        ),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    final filtered = ValueNotifier<List<CandidatoModel>>(candidatos);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ParentSearchSheet(
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

class _ParentSearchSheet extends StatefulWidget {
  final String label;
  final List<CandidatoModel> candidatos;
  final ValueNotifier<List<CandidatoModel>> filtered;
  final ValueChanged<CandidatoModel> onSelected;

  const _ParentSearchSheet({
    required this.label,
    required this.candidatos,
    required this.filtered,
    required this.onSelected,
  });

  @override
  State<_ParentSearchSheet> createState() => _ParentSearchSheetState();
}

class _ParentSearchSheetState extends State<_ParentSearchSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String query) {
    if (query.isEmpty) {
      widget.filtered.value = widget.candidatos;
      return;
    }
    final lower = query.toLowerCase();
    widget.filtered.value = widget.candidatos.where((c) {
      return c.arete.toLowerCase().contains(lower) ||
          c.nombre.toLowerCase().contains(lower);
    }).toList();
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
                          subtitle: Text('$especie • $sexo'),
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

class _FotoPicker extends StatelessWidget {
  final String? path;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _FotoPicker({
    required this.path,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Foto',
          prefixIcon: const Icon(Icons.camera_alt),
          suffixIcon: path != null
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClear,
                )
              : null,
        ),
        child: Row(
          children: [
            if (path != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(path!),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
            if (path != null) const SizedBox(width: 12),
            Text(
              path != null
                  ? path!.split('/').last
                  : 'Toca para seleccionar foto',
              style: TextStyle(
                color: path != null ? null : Colors.grey,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
