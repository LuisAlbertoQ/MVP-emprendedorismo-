class ProduccionModel {
  final String uid;
  final String animalUid;
  final DateTime fechaEsquila;
  final double pesoVellonKg;
  final double? rendimientoPct;
  final String observaciones;
  final String syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProduccionModel({
    required this.uid,
    required this.animalUid,
    required this.fechaEsquila,
    required this.pesoVellonKg,
    this.rendimientoPct,
    this.observaciones = '',
    this.syncStatus = 'sincronizado',
    this.createdAt,
    this.updatedAt,
  });

  factory ProduccionModel.fromJson(Map<String, dynamic> json) {
    return ProduccionModel(
      uid: json['uid'] as String,
      animalUid: json['animal_uid'] as String,
      fechaEsquila: DateTime.parse(json['fecha_esquila'] as String),
      pesoVellonKg: double.parse(json['peso_vellon_kg'].toString()),
      rendimientoPct: json['rendimiento_pct'] != null
          ? double.parse(json['rendimiento_pct'].toString())
          : null,
      observaciones: json['observaciones'] as String? ?? '',
      syncStatus: json['sync_status'] as String? ?? 'sincronizado',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fecha_esquila': fechaEsquila.toIso8601String().split('T')[0],
      'peso_vellon_kg': pesoVellonKg,
      'rendimiento_pct': rendimientoPct,
      'observaciones': observaciones,
    };
  }

  ProduccionModel copyWith({
    String? uid,
    String? animalUid,
    DateTime? fechaEsquila,
    double? pesoVellonKg,
    double? rendimientoPct,
    String? observaciones,
    String? syncStatus,
  }) {
    return ProduccionModel(
      uid: uid ?? this.uid,
      animalUid: animalUid ?? this.animalUid,
      fechaEsquila: fechaEsquila ?? this.fechaEsquila,
      pesoVellonKg: pesoVellonKg ?? this.pesoVellonKg,
      rendimientoPct: rendimientoPct ?? this.rendimientoPct,
      observaciones: observaciones ?? this.observaciones,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toSyncJson(String action) {
    return {
      'uid': uid,
      'animal_uid': animalUid,
      'fecha_esquila': fechaEsquila.toIso8601String().split('T')[0],
      'peso_vellon_kg': pesoVellonKg,
      'rendimiento_pct': rendimientoPct,
      'observaciones': observaciones,
      'action': action,
    };
  }
}

class ProduccionSyncChange {
  final String uid;
  final String animalUid;
  final DateTime fechaEsquila;
  final double pesoVellonKg;
  final double? rendimientoPct;
  final String observaciones;
  final String syncStatus;
  final DateTime? updatedAt;

  ProduccionSyncChange({
    required this.uid,
    required this.animalUid,
    required this.fechaEsquila,
    required this.pesoVellonKg,
    this.rendimientoPct,
    this.observaciones = '',
    this.syncStatus = 'sincronizado',
    this.updatedAt,
  });

  factory ProduccionSyncChange.fromJson(Map<String, dynamic> json) {
    return ProduccionSyncChange(
      uid: json['uid'] as String,
      animalUid: json['animal_uid'] as String,
      fechaEsquila: DateTime.parse(json['fecha_esquila'] as String),
      pesoVellonKg: double.parse(json['peso_vellon_kg'].toString()),
      rendimientoPct: json['rendimiento_pct'] != null
          ? double.parse(json['rendimiento_pct'].toString())
          : null,
      observaciones: json['observaciones'] as String? ?? '',
      syncStatus: json['sync_status'] as String? ?? 'sincronizado',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
