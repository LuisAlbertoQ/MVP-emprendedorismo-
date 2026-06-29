import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:front_genapp/data/services/api_service.dart';
import 'package:front_genapp/data/models/costo_model.dart';
import 'package:front_genapp/data/models/animal_model.dart';
import 'package:front_genapp/ui/core/widgets/animal_selector.dart';

class CostoFormScreen extends ConsumerStatefulWidget {
  const CostoFormScreen({super.key, this.uid});
  final String? uid;

  @override
  ConsumerState<CostoFormScreen> createState() => _CostoFormScreenState();
}

class _CostoFormScreenState extends ConsumerState<CostoFormScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late final TextEditingController _fechaCtrl;

  CandidatoModel? _animalSel;
  String _tipo = 'alimentacion';
  late DateTime _fecha;
  bool _saving = false;
  bool _loading = false;

  List<CandidatoModel> _candidatos = [];
  bool _loadingCandidatos = false;

  bool get _isEditing => widget.uid != null;

  @override
  void initState() {
    super.initState();
    _fecha = DateTime.now();
    _fechaCtrl = TextEditingController(text: DateFormat('dd/MM/yyyy').format(_fecha));
    if (_isEditing) {
      _loadData().then((_) => _loadCandidatos());
    } else {
      _loadCandidatos();
    }
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descCtrl.dispose();
    _fechaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCandidatos() async {
    setState(() => _loadingCandidatos = true);
    try {
      final params = <String, dynamic>{};
      final uids = [if (_animalSel != null) _animalSel!.uid];
      if (uids.isNotEmpty) params['include_uids'] = uids.join(',');
      final data = await _api.getList('/animales/candidatos/', queryParameters: params);
      _candidatos = data
          .map((e) => CandidatoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
    if (mounted) setState(() => _loadingCandidatos = false);
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('/costos/${widget.uid}/');
      final model = CostoModel.fromJson(data);
      _tipo = model.tipo;
      _montoCtrl.text = model.monto.toString();
      _fecha = model.fecha;
      _fechaCtrl.text = DateFormat('dd/MM/yyyy').format(_fecha);
      _descCtrl.text = model.descripcion;
      _animalSel = CandidatoModel(
        uid: model.animalUid,
        arete: data['animal_arete'] as String? ?? '',
        nombre: data['animal_nombre'] as String? ?? '',
        especie: data['animal_especie'] as String? ?? '',
        sexo: '',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_animalSel == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecciona un animal')));
      return;
    }
    setState(() => _saving = true);
    try {
      final data = CostoModel(
        animalUid: _animalSel!.uid,
        tipo: _tipo,
        monto: double.parse(_montoCtrl.text),
        fecha: _fecha,
        descripcion: _descCtrl.text,
      ).toJson();
      if (_isEditing) {
        await _api.patch('/costos/${widget.uid}/', data);
      } else {
        await _api.post('/costos/', data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? 'Costo actualizado' : 'Costo registrado')));
        context.pop();
      }
    } catch (e) {
      String msg = ApiService.extractError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar Costo' : 'Nuevo Costo')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Animal',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          AnimalSelector(
                            label: 'Animal',
                            icon: Icons.pets,
                            candidatos: _candidatos,
                            selected: _animalSel,
                            loading: _loadingCandidatos,
                            onSelected: (c) =>
                                setState(() => _animalSel = c),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detalles del Costo',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _tipo,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Costo *',
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'alimentacion',
                                  child: Text('Alimentación')),
                              DropdownMenuItem(
                                  value: 'sanidad',
                                  child: Text('Sanidad')),
                              DropdownMenuItem(
                                  value: 'esquila',
                                  child: Text('Esquila')),
                              DropdownMenuItem(
                                  value: 'transporte',
                                  child: Text('Transporte')),
                              DropdownMenuItem(
                                  value: 'otro', child: Text('Otro')),
                            ],
                            onChanged: (v) =>
                                setState(() => _tipo = v as String),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _montoCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Monto (S/) *',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final n = double.tryParse(v ?? '');
                              if (n == null || n <= 0) return 'Ingresa un monto válido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _fechaCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Fecha *',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final d = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now());
                              if (d != null) {
                                _fecha = d;
                                _fechaCtrl.text =
                                    DateFormat('dd/MM/yyyy').format(d);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                              prefixIcon: Icon(Icons.description),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Guardar'),
                  ),
                ],
              ),
            ),
    );
  }
}
