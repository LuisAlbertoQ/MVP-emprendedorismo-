import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_genapp/data/models/notificacion_model.dart';
import 'package:front_genapp/data/services/api_service.dart';

final _api = ApiService();

final notificacionesProvider = FutureProvider<List<NotificacionModel>>((ref) async {
  final data = await _api.getList('/auth/notificaciones/');
  return data.map((j) => NotificacionModel.fromJson(j)).toList();
});

final notificacionesNoLeidasProvider = FutureProvider<int>((ref) async {
  final data = await _api.get('/auth/notificaciones/no-leidas/');
  return data['count'] as int? ?? 0;
});

final notificacionesServiceProvider = Provider<NotificacionService>((ref) {
  return NotificacionService();
});

class NotificacionService {
  Future<void> marcarLeida(int id) async {
    await _api.patch('/auth/notificaciones/', {'id': id});
  }

  Future<void> marcarTodasLeidas() async {
    await _api.patch('/auth/notificaciones/', {});
  }
}