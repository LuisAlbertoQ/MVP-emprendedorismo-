import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:front_genapp/data/services/api_service.dart';
import 'package:front_genapp/data/models/empadre_model.dart';
import 'package:front_genapp/data/models/animal_model.dart';
import 'package:front_genapp/ui/core/widgets/animal_selector.dart';

class EmpadreFormScreen extends ConsumerStatefulWidget {
  const EmpadreFormScreen({super.key, this.uid});
  final String? uid;

  @override
  ConsumerState<EmpadreFormScreen> createState() => _EmpadreFormScreenState();
}

class _EmpadreFormScreenState extends ConsumerState<EmpadreFormScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _fechaCtrl = TextEditingController();

  CandidatoModel? _hembraSel;
  CandidatoModel? _machoSel;
  String _resultado = 'pendiente';
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
    _fechaCtrl.text = DateFormat('dd/MM/yyyy').format(_fecha);
    if (_isEditing) {
      _loadData().then((_) => _loadCandidatos());
    } else {
      _loadCandidatos();
    }
  }

  @override
  void dispose() {
    _fechaCtrl.dispose();
    super.dispose();
  }

  List<CandidatoModel> get _machos =>
      _candidatos.where((c) => c.sexo == 'macho').toList();

  List<CandidatoModel> get _hembras =>
      _candidatos.where((c) => c.sexo == 'hembra').toList();

  Future<void> _loadCandidatos() async {
    setState(() => _loadingCandidatos = true);
    try {
      final params = <String, dynamic>{};
      final uids = [if (_hembraSel != null) _hembraSel!.uid, if (_machoSel != null) _machoSel!.uid];
      if (uids.isNotEmpty) params['include_uids'] = uids.join(',');
      final data = await _api.getList('/animales/candidatos/', queryParameters: params);
      _candidatos = data
          .map((e) => CandidatoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar candidatos: $e')),
        );
      }
    }
    if (mounted) setState(() => _loadingCandidatos = false);
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('/empadres/${widget.uid}/');
      final model = EmpadreModel.fromJson(data);
      _fecha = model.fechaEmpadre;
      _fechaCtrl.text = DateFormat('dd/MM/yyyy').format(_fecha);
      _resultado = model.resultado;
      _hembraSel = CandidatoModel(
        uid: model.hembraUid,
        arete: data['hembra_arete'] as String? ?? '',
        nombre: data['hembra_nombre'] as String? ?? '',
        especie: data['hembra_especie'] as String? ?? '',
        sexo: 'hembra',
      );
      _machoSel = CandidatoModel(
        uid: model.machoUid,
        arete: data['macho_arete'] as String? ?? '',
        nombre: data['macho_nombre'] as String? ?? '',
        especie: data['macho_especie'] as String? ?? '',
        sexo: 'macho',
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
    if (_hembraSel == null || _machoSel == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecciona hembra y macho')));
      return;
    }
    setState(() => _saving = true);
    try {
      final data = EmpadreModel(
        hembraUid: _hembraSel!.uid,
        machoUid: _machoSel!.uid,
        fechaEmpadre: _fecha,
        resultado: _resultado,
      ).toJson();
      if (_isEditing) {
        await _api.patch('/empadres/${widget.uid}/', data);
      } else {
        await _api.post('/empadres/', data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? 'Empadre actualizado' : 'Empadre registrado')));
        context.pop();
      }
    } catch (e) {
      String msg = 'Error al guardar';
      msg = ApiService.extractError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar Empadre' : 'Nuevo Empadre')),
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
                          Text('Animales',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          AnimalSelector(
                            label: 'Hembra',
                            icon: Icons.female,
                            candidatos: _hembras,
                            selected: _hembraSel,
                            loading: _loadingCandidatos,
                            onSelected: (c) =>
                                setState(() => _hembraSel = c),
                          ),
                          const SizedBox(height: 16),
                          AnimalSelector(
                            label: 'Macho',
                            icon: Icons.male,
                            candidatos: _machos,
                            selected: _machoSel,
                            loading: _loadingCandidatos,
                            onSelected: (c) =>
                                setState(() => _machoSel = c),
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
                          Text('Detalles',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _fechaCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Fecha de Empadre *',
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
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _resultado,
                            decoration: const InputDecoration(
                              labelText: 'Resultado *',
                              prefixIcon: Icon(Icons.favorite_border),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'pendiente',
                                  child: Text('Pendiente')),
                              DropdownMenuItem(
                                  value: 'positivo',
                                  child: Text('Positivo')),
                              DropdownMenuItem(
                                  value: 'negativo',
                                  child: Text('Negativo')),
                              DropdownMenuItem(
                                  value: 'no_revisado',
                                  child: Text('No revisado')),
                            ],
                            onChanged: (v) =>
                                setState(() => _resultado = v as String),
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
