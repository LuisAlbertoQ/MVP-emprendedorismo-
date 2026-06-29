import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:front_genapp/data/services/api_service.dart';
import 'package:front_genapp/data/models/parto_model.dart';
import 'package:front_genapp/data/models/animal_model.dart';
import 'package:front_genapp/data/models/empadre_model.dart';
import 'package:front_genapp/ui/core/widgets/animal_selector.dart';

class PartoFormScreen extends ConsumerStatefulWidget {
  const PartoFormScreen({super.key, this.uid});
  final String? uid;

  @override
  ConsumerState<PartoFormScreen> createState() => _PartoFormScreenState();
}

class _PartoFormScreenState extends ConsumerState<PartoFormScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _fechaCtrl = TextEditingController();
  final _criasCtrl = TextEditingController(text: '1');
  final _incidenciasCtrl = TextEditingController();

  CandidatoModel? _hembraSel;
  late DateTime _fecha;
  bool _saving = false;
  bool _loading = false;

  List<CandidatoModel> _candidatos = [];
  bool _loadingCandidatos = false;

  List<EmpadreListModel> _empadres = [];
  EmpadreListModel? _empadreSel;
  bool _loadingEmpadres = false;

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
    _criasCtrl.dispose();
    _incidenciasCtrl.dispose();
    super.dispose();
  }

  List<CandidatoModel> get _hembras =>
      _candidatos.where((c) => c.sexo == 'hembra').toList();

  Future<void> _loadCandidatos() async {
    setState(() => _loadingCandidatos = true);
    try {
      final params = <String, dynamic>{};
      final uids = [if (_hembraSel != null) _hembraSel!.uid];
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

  Future<void> _loadEmpadres(String hembraUid) async {
    setState(() => _loadingEmpadres = true);
    try {
      final data = await _api.getList(
          '/empadres/?hembra_uid=$hembraUid&resultado=pendiente');
      _empadres = data
          .map((e) => EmpadreListModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (_empadreSel != null &&
          !_empadres.any((e) => e.uid == _empadreSel!.uid)) {
        _empadreSel = null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar empadres: $e')),
        );
      }
    }
    if (mounted) setState(() => _loadingEmpadres = false);
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('/partos/${widget.uid}/');
      final model = PartoModel.fromJson(data);
      _fecha = model.fechaParto;
      _fechaCtrl.text = DateFormat('dd/MM/yyyy').format(_fecha);
      _criasCtrl.text = model.numeroCrias.toString();
      _incidenciasCtrl.text = model.incidencias;
      _hembraSel = CandidatoModel(
        uid: model.hembraUid,
        arete: data['hembra_arete'] as String? ?? '',
        nombre: data['hembra_nombre'] as String? ?? '',
        especie: data['hembra_especie'] as String? ?? '',
        sexo: 'hembra',
      );
      if (model.empadreUid != null) {
        try {
          final ed = await _api.get('/empadres/${model.empadreUid}/');
          _empadreSel = EmpadreListModel(
            uid: model.empadreUid!,
            hembraArete: ed['hembra_arete'] as String? ?? '',
            machoArete: ed['macho_arete'] as String? ?? '',
            fechaEmpadre: DateTime.parse(ed['fecha_empadre'] as String),
            resultado: ed['resultado'] as String? ?? 'pendiente',
          );
        } catch (_) {}
      }
      await _loadEmpadres(model.hembraUid);
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
    if (_hembraSel == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecciona la hembra')));
      return;
    }
    setState(() => _saving = true);
    try {
      final data = PartoModel(
        hembraUid: _hembraSel!.uid,
        empadreUid: _empadreSel?.uid,
        fechaParto: _fecha,
        numeroCrias: int.tryParse(_criasCtrl.text) ?? 1,
        incidencias: _incidenciasCtrl.text,
      ).toJson();
      if (_isEditing) {
        await _api.patch('/partos/${widget.uid}/', data);
      } else {
        await _api.post('/partos/', data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? 'Parto actualizado' : 'Parto registrado')));
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
      appBar: AppBar(title: Text(_isEditing ? 'Editar Parto' : 'Nuevo Parto')),
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
                            label: 'Hembra',
                            icon: Icons.female,
                            candidatos: _hembras,
                            selected: _hembraSel,
                            loading: _loadingCandidatos,
                            onSelected: (c) {
                              setState(() {
                                _hembraSel = c;
                                _empadreSel = null;
                              });
                              if (c != null) _loadEmpadres(c.uid);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_hembraSel != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Empadre Relacionado',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            if (_loadingEmpadres)
                              const Padding(
                                padding: EdgeInsets.all(8),
                                child: LinearProgressIndicator(),
                              )
                            else if (_empadres.isEmpty)
                              Text('Sin empadres pendientes para esta hembra',
                                  style: TextStyle(color: Colors.grey.shade500))
                            else
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _empadreSel?.uid,
                                decoration: const InputDecoration(
                                  labelText: 'Empadre',
                                  prefixIcon: Icon(Icons.favorite_border),
                                ),
                                items: _empadres
                                    .map((e) => DropdownMenuItem(
                                          value: e.uid,
                                          child: Text(
                                              '${e.hembraArete} × ${e.machoArete} - ${DateFormat('dd/MM/yyyy').format(e.fechaEmpadre)}'),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(
                                    () => _empadreSel = _empadres.firstWhere(
                                        (e) => e.uid == v)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detalles del Parto',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _fechaCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Fecha de Parto *',
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
                          TextFormField(
                            controller: _criasCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Número de Crías *',
                              prefixIcon: Icon(Icons.child_care),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n < 1) return 'Debe ser al menos 1';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _incidenciasCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Incidencias',
                              hintText: 'Aborto, distocia, etc.',
                              prefixIcon: Icon(Icons.warning_amber),
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
