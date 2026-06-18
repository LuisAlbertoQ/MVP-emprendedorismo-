import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front_genapp/ui/core/theme.dart';
import 'package:front_genapp/ui/features/auth/providers/auth_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:front_genapp/ui/features/animales/providers/animal_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import 'dart:io';

class ReportesScreen extends ConsumerWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isPaid = user?.plan == 'basico' || user?.plan == 'criador';

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isPaid
            ? ListView(
                children: [
                  const _SectionHeader(title: 'Animales'),
                  const SizedBox(height: 8),
                  _ReporteCard(
                    icon: Icons.table_chart,
                    title: 'CSV - Animales',
                    subtitle: 'Lista completa de animales',
                    onPressed: () => _descargar(ref, context, 'animales', 'csv'),
                  ),
                  const SizedBox(height: 8),
                  _ReporteCard(
                    icon: Icons.picture_as_pdf,
                    title: 'PDF - Animales',
                    subtitle: 'Lista completa de animales',
                    onPressed: () => _descargar(ref, context, 'animales', 'pdf'),
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeader(title: 'Producción (Esquilas)'),
                  const SizedBox(height: 8),
                  _ReporteCard(
                    icon: Icons.table_chart,
                    title: 'CSV - Esquilas',
                    subtitle: 'Historial de esquilas con peso y rendimiento',
                    onPressed: () => _descargar(ref, context, 'esquilas', 'csv'),
                  ),
                  const SizedBox(height: 8),
                  _ReporteCard(
                    icon: Icons.picture_as_pdf,
                    title: 'PDF - Esquilas',
                    subtitle: 'Historial de esquilas con peso y rendimiento',
                    onPressed: () => _descargar(ref, context, 'esquilas', 'pdf'),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Reportes disponibles solo para planes Básico y Criador',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/perfil'),
                      child: const Text('Ver Planes'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _descargar(WidgetRef ref, BuildContext context, String tipo, String format) async {
    try {
      final api = ref.read(animalRepositoryProvider);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$tipo.$format');
      await api.download('/reporte/$tipo/?format=$format', file.path);
      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(file.path)], text: 'Reporte GeneApp Andina - $tipo',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold, color: AppTheme.primary,
    ));
  }
}

class _ReporteCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _ReporteCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.2),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.download),
        onTap: onPressed,
      ),
    );
  }
}
