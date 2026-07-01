import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_genapp/data/models/notificacion_model.dart';
import 'package:front_genapp/ui/features/perfil/providers/notificacion_provider.dart';

class NotificacionesScreen extends ConsumerStatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  ConsumerState<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends ConsumerState<NotificacionesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(notificacionesProvider);
      ref.invalidate(notificacionesNoLeidasProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncNotis = ref.watch(notificacionesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificacionesServiceProvider).marcarTodasLeidas();
              ref.invalidate(notificacionesProvider);
              ref.invalidate(notificacionesNoLeidasProvider);
            },
            child: const Text('Leer todas'),
          ),
        ],
      ),
      body: asyncNotis.when(
        data: (notis) {
          if (notis.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Sin notificaciones',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificacionesProvider);
              ref.invalidate(notificacionesNoLeidasProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notis.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _NotificacionTile(noti: notis[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _NotificacionTile extends ConsumerWidget {
  final NotificacionModel noti;
  const _NotificacionTile({required this.noti});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = noti.tipo == 'solicitud_aprobada'
        ? Icons.check_circle
        : noti.tipo == 'solicitud_rechazada'
            ? Icons.cancel
            : Icons.info;
    final color = noti.tipo == 'solicitud_aprobada'
        ? Colors.green
        : noti.tipo == 'solicitud_rechazada'
            ? Colors.red
            : Colors.blue;

    return InkWell(
      onTap: () async {
        if (!noti.leido) {
          await ref.read(notificacionesServiceProvider).marcarLeida(noti.id);
          ref.invalidate(notificacionesProvider);
          ref.invalidate(notificacionesNoLeidasProvider);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    noti.mensaje,
                    style: TextStyle(
                      fontWeight: noti.leido ? FontWeight.normal : FontWeight.w600,
                      color: noti.leido ? Colors.grey : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    noti.createdAt,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            if (!noti.leido)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}