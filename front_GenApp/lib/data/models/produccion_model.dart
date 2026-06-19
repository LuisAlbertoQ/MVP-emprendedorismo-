class ProduccionModel {
  final String uid;
  final String animalUid;
  final DateTime fechaEsquila;
  final double pesoVellonSucioKg;
  final double? pesoVellonLimpioKg;
  final int? numeroEsquila;
  final String observaciones;
  final String syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProduccionModel({
    required this.uid,
    required this.animalUid,
    required this.fechaEsquila,
    required this.pesoVellonSucioKg,
    this.pesoVellonLimpioKg,
    this.numeroEsquila,
    this.observaciones = '',
    this.syncStatus = 'sincronizado',
    this.createdAt,
    this.updatedAt,
  });

  double? get rendimientoPct {
    if (pesoVellonSucioKg > 0 && pesoVellonLimpioKg != null) {
      return (pesoVellonLimpioKg! / pesoVellonSucioKg) * 100;
    }
    return null;
  }

  factory ProduccionModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return ProduccionModel(
      uid: json['uid'] as String? ?? '',
      animalUid: json['animal_uid'] as String? ?? '',
      fechaEsquila: parseDate(json['fecha_esquila']) ?? DateTime.now(),
      pesoVellonSucioKg: double.tryParse(json['peso_vellon_sucio_kg']?.toString() ?? '') ?? 0,
      pesoVellonLimpioKg: json['peso_vellon_limpio_kg'] != null
          ? double.tryParse(json['peso_vellon_limpio_kg'].toString())
          : null,
      numeroEsquila: json['numero_esquila'] as int?,
      observaciones: json['observaciones'] as String? ?? '',
      syncStatus: json['sync_status'] as String? ?? 'sincronizado',
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fecha_esquila': fechaEsquila.toIso8601String().split('T')[0],
      'peso_vellon_sucio_kg': pesoVellonSucioKg,
      'peso_vellon_limpio_kg': pesoVellonLimpioKg,
      'numero_esquila': numeroEsquila,
      'observaciones': observaciones,
    };
  }

  ProduccionModel copyWith({
    String? uid,
    String? animalUid,
    DateTime? fechaEsquila,
    double? pesoVellonSucioKg,
    double? pesoVellonLimpioKg,
    int? numeroEsquila,
    String? observaciones,
    String? syncStatus,
  }) {
    return ProduccionModel(
      uid: uid ?? this.uid,
      animalUid: animalUid ?? this.animalUid,
      fechaEsquila: fechaEsquila ?? this.fechaEsquila,
      pesoVellonSucioKg: pesoVellonSucioKg ?? this.pesoVellonSucioKg,
      pesoVellonLimpioKg: pesoVellonLimpioKg ?? this.pesoVellonLimpioKg,
      numeroEsquila: numeroEsquila ?? this.numeroEsquila,
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
      'peso_vellon_sucio_kg': pesoVellonSucioKg,
      'peso_vellon_limpio_kg': pesoVellonLimpioKg,
      'numero_esquila': numeroEsquila,
      'observaciones': observaciones,
      'action': action,
    };
  }
}

class ProduccionSyncChange {
  final String uid;
  final String animalUid;
  final DateTime fechaEsquila;
  final double pesoVellonSucioKg;
  final double? pesoVellonLimpioKg;
  final int? numeroEsquila;
  final String observaciones;
  final String syncStatus;
  final DateTime? updatedAt;

  ProduccionSyncChange({
    required this.uid,
    required this.animalUid,
    required this.fechaEsquila,
    required this.pesoVellonSucioKg,
    this.pesoVellonLimpioKg,
    this.numeroEsquila,
    this.observaciones = '',
    this.syncStatus = 'sincronizado',
    this.updatedAt,
  });

  factory ProduccionSyncChange.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return ProduccionSyncChange(
      uid: json['uid'] as String? ?? '',
      animalUid: json['animal_uid'] as String? ?? '',
      fechaEsquila: parseDate(json['fecha_esquila']) ?? DateTime.now(),
      pesoVellonSucioKg: double.tryParse(json['peso_vellon_sucio_kg']?.toString() ?? '') ?? 0,
      pesoVellonLimpioKg: json['peso_vellon_limpio_kg'] != null
          ? double.tryParse(json['peso_vellon_limpio_kg'].toString())
          : null,
      numeroEsquila: json['numero_esquila'] as int?,
      observaciones: json['observaciones'] as String? ?? '',
      syncStatus: json['sync_status'] as String? ?? 'sincronizado',
      updatedAt: parseDate(json['updated_at']),
    );
  }
}
