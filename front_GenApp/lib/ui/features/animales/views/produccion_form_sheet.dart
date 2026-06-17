import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:front_genapp/data/models/produccion_model.dart';
import 'package:front_genapp/ui/features/animales/providers/animal_provider.dart';

class ProduccionFormSheet extends ConsumerStatefulWidget {
  final String animalUid;
  final ProduccionModel? produccion;
  const ProduccionFormSheet(
      {super.key, required this.animalUid, this.produccion});

  @override
  ProduccionFormSheetState createState() => ProduccionFormSheetState();
}

class ProduccionFormSheetState extends ConsumerState<ProduccionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _fechaEsquila;
  late TextEditingController _pesoCtrl;
  late TextEditingController _rendimientoCtrl;
  late TextEditingController _observacionesCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.produccion;
    _fechaEsquila = p?.fechaEsquila ?? DateTime.now();
    _pesoCtrl = TextEditingController(
        text: p != null ? p.pesoVellonKg.toString() : '');
    _rendimientoCtrl = TextEditingController(
        text: p?.rendimientoPct?.toString() ?? '');
    _observacionesCtrl = TextEditingController(text: p?.observaciones ?? '');
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _rendimientoCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaEsquila,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fechaEsquila = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final p = ProduccionModel(
        uid: widget.produccion?.uid ?? '',
        animalUid: widget.animalUid,
        fechaEsquila: _fechaEsquila,
        pesoVellonKg: double.parse(_pesoCtrl.text),
        rendimientoPct: _rendimientoCtrl.text.isNotEmpty
            ? double.tryParse(_rendimientoCtrl.text)
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
                  decoration: const InputDecoration(
                    labelText: 'Fecha de Esquila',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_fechaEsquila),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pesoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Peso del Vellón (kg)',
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
                controller: _rendimientoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Rendimiento (%)',
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
