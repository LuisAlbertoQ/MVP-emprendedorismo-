class EmpadreListModel {
  final String uid;
  final String hembraArete;
  final String machoArete;
  final DateTime fechaEmpadre;
  final String resultado;
  final DateTime? fechaDxGestacion;
  final String observaciones;

  EmpadreListModel({
    required this.uid,
    required this.hembraArete,
    required this.machoArete,
    required this.fechaEmpadre,
    this.resultado = 'pendiente',
    this.fechaDxGestacion,
    this.observaciones = '',
  });

  factory EmpadreListModel.fromJson(Map<String, dynamic> json) {
    return EmpadreListModel(
      uid: json['uid'] as String,
      hembraArete: json['hembra_arete'] as String? ?? '',
      machoArete: json['macho_arete'] as String? ?? '',
      fechaEmpadre: DateTime.parse(json['fecha_empadre'] as String),
      resultado: json['resultado'] as String? ?? 'pendiente',
      fechaDxGestacion: json['fecha_dx_gestacion'] != null
          ? DateTime.tryParse(json['fecha_dx_gestacion'] as String)
          : null,
      observaciones: json['observaciones'] as String? ?? '',
    );
  }
}

class EmpadreModel {
  final String? uid;
  final String hembraUid;
  final String machoUid;
  final DateTime fechaEmpadre;
  final DateTime? fechaDxGestacion;
  final String resultado;
  final String observaciones;

  EmpadreModel({
    this.uid,
    required this.hembraUid,
    required this.machoUid,
    required this.fechaEmpadre,
    this.fechaDxGestacion,
    this.resultado = 'pendiente',
    this.observaciones = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'hembra_write_uid': hembraUid,
      'macho_write_uid': machoUid,
      'fecha_empadre': fechaEmpadre.toIso8601String().split('T').first,
      'fecha_dx_gestacion': fechaDxGestacion?.toIso8601String().split('T').first,
      'resultado': resultado,
      'observaciones': observaciones,
    };
  }

  factory EmpadreModel.fromJson(Map<String, dynamic> json) {
    return EmpadreModel(
      uid: json['uid'] as String?,
      hembraUid: json['hembra_uid'] as String? ?? '',
      machoUid: json['macho_uid'] as String? ?? '',
      fechaEmpadre: DateTime.parse(json['fecha_empadre'] as String),
      fechaDxGestacion: json['fecha_dx_gestacion'] != null
          ? DateTime.tryParse(json['fecha_dx_gestacion'] as String)
          : null,
      resultado: json['resultado'] as String? ?? 'pendiente',
      observaciones: json['observaciones'] as String? ?? '',
    );
  }
}

String resultadoGestacionLabel(String value) {
  switch (value) {
    case 'pendiente':
      return 'Pendiente';
    case 'positivo':
      return 'Positivo';
    case 'negativo':
      return 'Negativo';
    case 'no_revisado':
      return 'No revisado';
    default:
      return value;
  }
}
