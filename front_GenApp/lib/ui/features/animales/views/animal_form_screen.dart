import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:front_genapp/data/services/api_service.dart';
import 'package:front_genapp/data/models/animal_model.dart' show AnimalModel, CandidatoModel;
import 'package:front_genapp/ui/core/constants.dart';
import 'package:front_genapp/ui/core/theme.dart';
import 'package:front_genapp/ui/core/widgets/loading_button.dart';
import 'package:front_genapp/ui/core/widgets/animal_selector.dart';
import 'package:front_genapp/ui/features/animales/providers/animal_provider.dart';

class AnimalFormScreen extends ConsumerStatefulWidget {
  final String? uid;
  const AnimalFormScreen({super.key, this.uid});

  @override
  ConsumerState<AnimalFormScreen> createState() => _AnimalFormScreenState();
}

const _razasPorEspecie = <String, List<String>>{
  'alpaca': ['huacaya', 'suri'],
  'llama': ['kara', 'chaqu'],
  'ovino': ['criollo', 'corriedale', 'junin', 'hampshire_down', 'black_belly', 'assaf'],
};

const _razaLabel = <String, String>{
  'huacaya': 'Huacaya',
  'suri': 'Suri',
  'kara': "K'ara",
  'chaqu': 'Chaqu',
  'criollo': 'Criollo',
  'corriedale': 'Corriedale',
  'junin': 'Junín',
  'hampshire_down': 'Hampshire Down',
  'black_belly': 'Black Belly',
  'assaf': 'Assaf',
};

class _AnimalFormScreenState extends ConsumerState<AnimalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _areteCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  String _especie = 'alpaca';
  String _raza = '';
  String _sexo = 'macho';
  String _estado = 'VIVO';
  DateTime _fechaNac = DateTime.now();
  final _pesoNacCtrl = TextEditingController();
  bool _saving = false;

  CandidatoModel? _padre;
  CandidatoModel? _madre;

  List<CandidatoModel> _candidatos = [];
  bool _loadingCandidatos = false;

  String? _fotoPath;
  String? _existingFotoUrl;
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

  Future<void> _loadCandidatos({List<String> includeUids = const []}) async {
    setState(() => _loadingCandidatos = true);
    try {
      final repo = ref.read(animalRepositoryProvider);
      _candidatos = await repo.getCandidatos(includeUids: includeUids);
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
      _raza = animal.raza;
      _obsCtrl.text = animal.observaciones;
      _especie = animal.especie;
      _sexo = animal.sexo;
      _estado = animal.estado;
      _motivoCtrl.text = animal.motivoEstado;
      _existingFotoUrl = animal.foto;
      _fechaNac = animal.fechaNacimiento;
      if (animal.pesoNacimientoKg != null) {
        _pesoNacCtrl.text = animal.pesoNacimientoKg.toString();
      }
      await _loadCandidatos(
        includeUids: [
          if (animal.padreUid != null) animal.padreUid!,
          if (animal.madreUid != null) animal.madreUid!,
        ],
      );
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
    _motivoCtrl.dispose();
    _obsCtrl.dispose();
    _pesoNacCtrl.dispose();
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
        estado: _estado,
        motivoEstado: _motivoCtrl.text.trim(),
        fechaNacimiento: _fechaNac,
        nombre: _nombreCtrl.text.trim(),
        raza: _raza,
        padreUid: _padre?.uid,
        madreUid: _madre?.uid,
        observaciones: _obsCtrl.text.trim(),
        pesoNacimientoKg: _pesoNacCtrl.text.isNotEmpty
            ? double.tryParse(_pesoNacCtrl.text)
            : null,
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
          SnackBar(content: Text(ApiService.extractError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
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
              _buildSection('Identificación', [
                TextFormField(
                  controller: _areteCtrl,
                  decoration: InputDecoration(
                    labelText: 'Arete *',
                    prefixIcon: const Icon(Icons.tag),
                    errorText: _fieldErrors['arete'],
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (v.length > 50) return 'Máximo 50 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.pets),
                  ),
                  validator: (v) {
                    if (v != null && v.length > 100) return 'Máximo 100 caracteres';
                    return null;
                  },
                ),
              ]),
              const SizedBox(height: 16),
              _buildSection('Clasificación', [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _especie,
                        decoration: const InputDecoration(
                          labelText: 'Especie *',
                          prefixIcon: Icon(Icons.pets),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'alpaca', child: Text('Alpaca')),
                          DropdownMenuItem(value: 'llama', child: Text('Llama')),
                          DropdownMenuItem(value: 'ovino', child: Text('Ovino')),
                        ],
                        onChanged: (v) {
                          if (v != null && v != _especie) {
                            final razas = _razasPorEspecie[v]!;
                            if (!razas.contains(_raza)) _raza = '';
                            setState(() => _especie = v);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _raza.isNotEmpty ? _raza : null,
                        decoration: const InputDecoration(
                          labelText: 'Raza',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _razasPorEspecie[_especie]!
                            .map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                    _razaLabel[r] ?? r,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _raza = v ?? ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SexoCard(
                        icon: Icons.male,
                        label: 'Macho',
                        selected: _sexo == 'macho',
                        onTap: () => setState(() => _sexo = 'macho'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SexoCard(
                        icon: Icons.female,
                        label: 'Hembra',
                        selected: _sexo == 'hembra',
                        onTap: () => setState(() => _sexo = 'hembra'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _estado,
                  decoration: const InputDecoration(
                    labelText: 'Estado *',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'VIVO', child: Text('Vivo')),
                    DropdownMenuItem(value: 'VENDIDO', child: Text('Vendido')),
                    DropdownMenuItem(value: 'MUERTO', child: Text('Muerto')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _estado = v);
                  },
                ),
                if (_estado != 'VIVO') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _motivoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Motivo del cambio de estado *',
                      prefixIcon: Icon(Icons.info_outline),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 2,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requerido cuando el estado no es Vivo';
                      return null;
                    },
                  ),
                ],
              ]),
              const SizedBox(height: 16),
              _buildSection('Detalles Físicos', [
                TextFormField(
                  controller: _pesoNacCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Peso al Nacimiento (kg)',
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final n = double.tryParse(v);
                      if (n == null) return 'Debe ser un número válido';
                      if (n <= 0) return 'Debe ser mayor a 0';
                      if (n > 999.99) return 'No puede superar 999.99 kg';
                    }
                    return null;
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
              ]),
              const SizedBox(height: 16),
              _buildSection('Genealogía', [
                AnimalSelector(
                  label: 'Padre',
                  icon: Icons.male,
                  errorText: _fieldErrors['padre'],
                  candidatos: _candidatos,
                  selected: _padre,
                  loading: _loadingCandidatos,
                  onSelected: (c) => setState(() => _padre = c),
                ),
                const SizedBox(height: 16),
                AnimalSelector(
                  label: 'Madre',
                  icon: Icons.female,
                  errorText: _fieldErrors['madre'],
                  candidatos: _candidatos,
                  selected: _madre,
                  loading: _loadingCandidatos,
                  onSelected: (c) => setState(() => _madre = c),
                ),
              ]),
              const SizedBox(height: 16),
              _buildSection('Adicional', [
                _FotoPicker(
                  path: _fotoPath,
                  existingUrl: _existingFotoUrl,
                  onPick: _pickFoto,
                  onClear: () {
                    setState(() {
                      _fotoPath = null;
                      _existingFotoUrl = null;
                    });
                  },
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
              ]),
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

class _SexoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SexoCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: selected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppTheme.primary : Colors.grey.shade300,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, size: 32,
                  color: selected ? AppTheme.primary : Colors.grey),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? AppTheme.primary : Colors.grey,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _FotoPicker extends StatelessWidget {
  final String? path;
  final String? existingUrl;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _FotoPicker({
    required this.path,
    this.existingUrl,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocal = path != null;
    final hasExisting = !hasLocal && existingUrl != null && existingUrl!.isNotEmpty;

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Foto',
          prefixIcon: const Icon(Icons.camera_alt),
          suffixIcon: hasLocal || hasExisting
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClear,
                )
              : null,
        ),
        child: Row(
          children: [
            if (hasLocal)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(path!),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              )
            else if (hasExisting)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  existingUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
            if (hasLocal || hasExisting) const SizedBox(width: 12),
            Text(
              hasLocal
                  ? path!.split('/').last
                  : hasExisting
                      ? 'Foto actual'
                      : 'Toca para seleccionar foto',
              style: TextStyle(
                color: hasLocal || hasExisting ? null : Colors.grey,
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
