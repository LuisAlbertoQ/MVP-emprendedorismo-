class UserModel {
  final int id;
  final String telefono;
  final String firstName;
  final String plan;
  final int limiteAnimales;
  final int animalesCount;
  final int generationsAllowed;
  final DateTime? createdAt;
  final SolicitudPendiente? solicitudPendiente;

  UserModel({
    required this.id,
    required this.telefono,
    required this.firstName,
    required this.plan,
    required this.limiteAnimales,
    required this.animalesCount,
    required this.generationsAllowed,
    this.createdAt,
    this.solicitudPendiente,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      telefono: json['telefono'] as String,
      firstName: json['first_name'] as String? ?? '',
      plan: json['plan'] as String? ?? 'gratuito',
      limiteAnimales: json['limite_animales'] as int? ?? 20,
      animalesCount: json['animales_count'] as int? ?? 0,
      generationsAllowed: json['generations_allowed'] as int? ?? 2,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      solicitudPendiente: json['solicitud_pendiente'] != null
          ? SolicitudPendiente.fromJson(
              json['solicitud_pendiente'] as Map<String, dynamic>)
          : null,
    );
  }
}

class SolicitudPendiente {
  final String uid;
  final String planSolicitado;
  final String monto;
  final String createdAt;

  SolicitudPendiente({
    required this.uid,
    required this.planSolicitado,
    required this.monto,
    required this.createdAt,
  });

  factory SolicitudPendiente.fromJson(Map<String, dynamic> json) {
    return SolicitudPendiente(
      uid: json['uid'] as String,
      planSolicitado: json['plan_solicitado'] as String,
      monto: json['monto'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}
