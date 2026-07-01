import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:front_genapp/data/services/api_service.dart';

class PagoScreen extends ConsumerStatefulWidget {
  final String plan;
  const PagoScreen({super.key, required this.plan});

  @override
  ConsumerState<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends ConsumerState<PagoScreen> {
  final _api = ApiService();
  final _picker = ImagePicker();
  File? _comprobante;
  final _operacionCtrl = TextEditingController();
  Map<String, dynamic>? _datosPago;
  bool _loading = true;
  bool _saving = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _loadDatos();
  }

  Future<void> _loadDatos() async {
    try {
      final data = await _api.get('/auth/datos-pago/');
      setState(() => _datosPago = data);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) setState(() => _comprobante = File(xfile.path));
  }

  Future<void> _subir() async {
    if (_comprobante == null) return;
    setState(() => _saving = true);
    final fields = <String, dynamic>{'plan_solicitado': widget.plan};
    if (_operacionCtrl.text.trim().isNotEmpty) {
      fields['numero_operacion'] = _operacionCtrl.text.trim();
    }
    try {
      await _api.postMultipart(
        '/auth/solicitar-pago/',
        fields,
        _comprobante!.path,
      );
      setState(() => _success = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.extractError(e))),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _success
              ? _successView()
              : _paymentForm(),
    );
  }

  Widget _paymentForm() {
    final montoKey = widget.plan == 'criador' ? 'monto_criador' : 'monto_basico';
    final monto = _datosPago?[montoKey]?.toString() ?? '—';
    final celular = _datosPago?['celular'] as String? ?? '—';
    final qrUrl = _datosPago?['qr'] as String?;
    final mediaUrl = (ApiService.baseUrl.replaceFirst('/api/v1', ''));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.payment, size: 48, color: Colors.green),
                const SizedBox(height: 12),
                Text(
                  'Paga con Yape o Plin',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Plan ${widget.plan == 'criador' ? 'Criador' : 'Básico'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Monto: S/ $monto',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
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
              children: [
                const Text('Datos para el pago',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (qrUrl != null && qrUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      qrUrl.startsWith('http') ? qrUrl : '$mediaUrl$qrUrl',
                      height: 180,
                      width: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        width: 180,
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.qr_code, size: 80),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_android, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      celular,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Escanea el QR o transfiere al número',
                  style: TextStyle(color: Colors.grey),
                ),
                const Text(
                  '2. Toma una captura del comprobante',
                  style: TextStyle(color: Colors.grey),
                ),
                const Text(
                  '3. Súbela aquí abajo',
                  style: TextStyle(color: Colors.grey),
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
              children: [
                const Text('Sube tu comprobante',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _operacionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'N° de operación (opcional)',
                    hintText: 'Ej: 123456',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                if (_comprobante != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _comprobante!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Toca para seleccionar',
                              style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (_comprobante != null)
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Cambiar imagen'),
                  )
                else
                  FilledButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Seleccionar comprobante'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _comprobante != null && !_saving ? _subir : null,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar solicitud'),
        ),
      ],
    );
  }

  Widget _successView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              'Solicitud enviada',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu solicitud de pago está pendiente de revisión.\n'
              'Te notificaremos cuando sea aprobada.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Volver al perfil'),
            ),
          ],
        ),
      ),
    );
  }
}