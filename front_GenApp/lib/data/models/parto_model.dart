class PartoListModel {
  final String uid;
  final String hembraArete;
  final DateTime fechaParto;
  final DateTime? fechaProbable;
  final int numeroCrias;
  final String incidencias;

  PartoListModel({
    required this.uid,
    required this.hembraArete,
    required this.fechaParto,
    this.fechaProbable,
    this.numeroCrias = 1,
    this.incidencias = '',
  });

  factory PartoListModel.fromJson(Map<String, dynamic> json) {
    return PartoListModel(
      uid: json['uid'] as String,
      hembraArete: json['hembra_arete'] as String? ?? '',
      fechaParto: DateTime.parse(json['fecha_parto'] as String),
      fechaProbable: json['fecha_probable'] != null
          ? DateTime.tryParse(json['fecha_probable'] as String)
          : null,
      numeroCrias: json['numero_crias'] as int? ?? 1,
      incidencias: json['incidencias'] as String? ?? '',
    );
  }
}

class PartoModel {
  final String? uid;
  final String hembraUid;
  final String? empadreUid;
  final DateTime fechaParto;
  final int numeroCrias;
  final String incidencias;
  final String observaciones;

  PartoModel({
    this.uid,
    required this.hembraUid,
    this.empadreUid,
    required this.fechaParto,
    this.numeroCrias = 1,
    this.incidencias = '',
    this.observaciones = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'hembra_write_uid': hembraUid,
      'empadre_write_uid': empadreUid,
      'fecha_parto': fechaParto.toIso8601String().split('T').first,
      'numero_crias': numeroCrias,
      'incidencias': incidencias,
      'observaciones': observaciones,
    };
  }

  factory PartoModel.fromJson(Map<String, dynamic> json) {
    return PartoModel(
      uid: json['uid'] as String?,
      hembraUid: json['hembra_uid'] as String? ?? '',
      empadreUid: json['empadre_uid'] as String?,
      fechaParto: DateTime.parse(json['fecha_parto'] as String),
      numeroCrias: json['numero_crias'] as int? ?? 1,
      incidencias: json['incidencias'] as String? ?? '',
      observaciones: json['observaciones'] as String? ?? '',
    );
  }
}
