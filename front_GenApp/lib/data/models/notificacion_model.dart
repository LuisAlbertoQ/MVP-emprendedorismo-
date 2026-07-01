class NotificacionModel {
  final int id;
  final String mensaje;
  final String tipo;
  final bool leido;
  final String createdAt;

  NotificacionModel({
    required this.id,
    required this.mensaje,
    required this.tipo,
    required this.leido,
    required this.createdAt,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      id: json['id'] as int,
      mensaje: json['mensaje'] as String,
      tipo: json['tipo'] as String,
      leido: json['leido'] as bool,
      createdAt: json['created_at'] as String,
    );
  }
}