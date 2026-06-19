import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:front_genapp/data/models/produccion_model.dart';
import 'package:front_genapp/ui/features/animales/providers/animal_provider.dart';

class ProduccionFormSheet extends ConsumerStatefulWidget {
  final String animalUid;
  final ProduccionModel? produccion;
  final DateTime? animalFechaNacimiento;
  const ProduccionFormSheet(
      {super.key, required this.animalUid, this.produccion, this.animalFechaNacimiento});

  @override
  ProduccionFormSheetState createState() => ProduccionFormSheetState();
}

class ProduccionFormSheetState extends ConsumerState<ProduccionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _fechaEsquila;
  late TextEditingController _pesoSucioCtrl;
  late TextEditingController _pesoLimpioCtrl;
  late TextEditingController _numeroEsquilaCtrl;
  late TextEditingController _observacionesCtrl;
  bool _saving = false;
  String? _fechaError;

  @override
  void initState() {
    super.initState();
    final p = widget.produccion;
    _fechaEsquila = p?.fechaEsquila ?? DateTime.now();
    _pesoSucioCtrl = TextEditingController(
        text: p != null ? p.pesoVellonSucioKg.toString() : '');
    _pesoLimpioCtrl = TextEditingController(
        text: p?.pesoVellonLimpioKg?.toString() ?? '');
    _numeroEsquilaCtrl = TextEditingController(
        text: p?.numeroEsquila?.toString() ?? '');
    _observacionesCtrl = TextEditingController(text: p?.observaciones ?? '');
  }

  @override
  void dispose() {
    _pesoSucioCtrl.dispose();
    _pesoLimpioCtrl.dispose();
    _numeroEsquilaCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final minDate = widget.animalFechaNacimiento ?? DateTime(2000);
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaEsquila.isBefore(minDate) ? minDate : _fechaEsquila,
      firstDate: minDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaEsquila = picked;
        _fechaError = null;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.animalFechaNacimiento != null &&
        _fechaEsquila.isBefore(widget.animalFechaNacimiento!)) {
      setState(() => _fechaError = 'No puede ser anterior al nacimiento del animal');
      return;
    }
    setState(() => _saving = true);
    try {
      final p = ProduccionModel(
        uid: widget.produccion?.uid ?? '',
        animalUid: widget.animalUid,
        fechaEsquila: _fechaEsquila,
        pesoVellonSucioKg: double.parse(_pesoSucioCtrl.text),
        pesoVellonLimpioKg: _pesoLimpioCtrl.text.isNotEmpty
            ? double.tryParse(_pesoLimpioCtrl.text)
            : null,
        numeroEsquila: _numeroEsquilaCtrl.text.isNotEmpty
            ? int.tryParse(_numeroEsquilaCtrl.text)
            : null,
        observaciones: _observacionesCtrl.text,
      );
      if (widget.produccion != null) {
        await ref.read(animalRepositoryProvider).updateProduccion(
            widget.produccion!.uid, p);
      } else {
        await ref.read(animalRepositoryProvider)
            .createProduccion(widget.animalUid, p);
      }
      ref.invalidate(produccionListProvider(widget.animalUid));
      if (mounted && context.mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.produccion != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit ? 'Editar Esquila' : 'Nueva Esquila',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de Esquila',
                    prefixIcon: const Icon(Icons.calendar_today),
                    errorText: _fechaError,
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_fechaEsquila),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pesoSucioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Peso Vellón Sucio (kg) *',
                  prefixIcon: Icon(Icons.scale),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obligatorio';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pesoLimpioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Peso Vellón Limpio (kg)',
                  prefixIcon: Icon(Icons.cleaning_services),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    final n = double.tryParse(v);
                    if (n == null) return 'Debe ser un número válido';
                    if (n <= 0) return 'Debe ser mayor a 0';
                    if (n > 9999.99) return 'No puede superar 9999.99 kg';
                    final sucio = double.tryParse(_pesoSucioCtrl.text);
                    if (sucio != null && n > sucio) {
                      return 'No puede ser mayor al peso sucio (${sucio.toStringAsFixed(2)} kg)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numeroEsquilaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Número de Esquila',
                  prefixIcon: Icon(Icons.tag),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    final n = int.tryParse(v);
                    if (n == null) return 'Debe ser un número entero';
                    if (n <= 0) return 'Debe ser un entero positivo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacionesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEdit ? 'Guardar Cambios' : 'Guardar Esquila'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
