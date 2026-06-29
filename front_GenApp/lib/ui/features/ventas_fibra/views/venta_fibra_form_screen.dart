import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:front_genapp/data/services/api_service.dart';
import 'package:front_genapp/data/models/venta_fibra_model.dart';
import 'package:front_genapp/data/models/animal_model.dart';
import 'package:front_genapp/ui/core/widgets/animal_selector.dart';

class VentaFibraFormScreen extends ConsumerStatefulWidget {
  const VentaFibraFormScreen({super.key, this.uid});
  final String? uid;

  @override
  ConsumerState<VentaFibraFormScreen> createState() =>
      _VentaFibraFormScreenState();
}

class _VentaFibraFormScreenState extends ConsumerState<VentaFibraFormScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _kgCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _compradorCtrl = TextEditingController();
  late final TextEditingController _fechaCtrl;

  CandidatoModel? _animalSel;
  late DateTime _fecha;
  bool _saving = false;
  bool _loading = false;

  List<CandidatoModel> _candidatos = [];
  bool _loadingCandidatos = false;

  bool get _isEditing => widget.uid != null;

  double? get _previewTotal {
    final kg = double.tryParse(_kgCtrl.text);
    final precio = double.tryParse(_precioCtrl.text);
    if (kg != null && precio != null) return kg * precio;
    return null;
  }

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
    _kgCtrl.dispose();
    _precioCtrl.dispose();
    _compradorCtrl.dispose();
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
      final data = await _api.get('/ventas-fibra/${widget.uid}/');
      final model = VentaFibraModel.fromJson(data);
      _kgCtrl.text = model.kgVendidos.toString();
      _precioCtrl.text = model.precioKg.toString();
      _compradorCtrl.text = model.comprador;
      _fecha = model.fechaVenta;
      _fechaCtrl.text = DateFormat('dd/MM/yyyy').format(_fecha);
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
      final data = VentaFibraModel(
        animalUid: _animalSel!.uid,
        kgVendidos: double.parse(_kgCtrl.text),
        precioKg: double.parse(_precioCtrl.text),
        comprador: _compradorCtrl.text,
        fechaVenta: _fecha,
      ).toJson();
      if (_isEditing) {
        await _api.patch('/ventas-fibra/${widget.uid}/', data);
      } else {
        await _api.post('/ventas-fibra/', data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isEditing ? 'Venta actualizada' : 'Venta registrada')));
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
    final total = _previewTotal;
    return Scaffold(
      appBar:
          AppBar(title: Text(_isEditing ? 'Editar Venta de Fibra' : 'Nueva Venta de Fibra')),
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
                          Text('Detalles de la Venta',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _kgCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Kilogramos vendidos *',
                              prefixIcon: Icon(Icons.monitor_weight),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final n = double.tryParse(v ?? '');
                              if (n == null || n <= 0) {
                                return 'Ingresa un valor válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _precioCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Precio por kg (S/) *',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final n = double.tryParse(v ?? '');
                              if (n == null || n <= 0) {
                                return 'Ingresa un precio válido';
                              }
                              return null;
                            },
                          ),
                          if (total != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Total estimado: S/${total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _compradorCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Comprador',
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _fechaCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Fecha de Venta *',
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
