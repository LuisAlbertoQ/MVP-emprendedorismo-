class AnimalModel {
  final String uid;
  final String arete;
  final String especie;
  final String sexo;
  final DateTime fechaNacimiento;
  final String nombre;
  final String raza;
  final String? padre;
  final String? madre;
  final String? padreUid;
  final String? madreUid;
  final String? foto;
  final String observaciones;
  final bool activo;
  final String syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? categoriaEdad;

  AnimalModel({
    required this.uid,
    required this.arete,
    required this.especie,
    required this.sexo,
    required this.fechaNacimiento,
    this.nombre = '',
    this.raza = '',
    this.padre,
    this.madre,
    this.padreUid,
    this.madreUid,
    this.foto,
    this.observaciones = '',
    this.activo = true,
    this.syncStatus = 'sincronizado',
    this.createdAt,
    this.updatedAt,
    this.categoriaEdad,
  });

  factory AnimalModel.fromJson(Map<String, dynamic> json) {
    return AnimalModel(
      uid: json['uid'] as String,
      arete: json['arete'] as String,
      especie: json['especie'] as String,
      sexo: json['sexo'] as String,
      fechaNacimiento: DateTime.parse(json['fecha_nacimiento'] as String),
      nombre: json['nombre'] as String? ?? '',
      raza: json['raza'] as String? ?? '',
      padre: json['padre'] as String?,
      madre: json['madre'] as String?,
      padreUid: json['padre_uid'] as String?,
      madreUid: json['madre_uid'] as String?,
      foto: json['foto'] as String?,
      observaciones: json['observaciones'] as String? ?? '',
      activo: json['activo'] as bool? ?? true,
      syncStatus: json['sync_status'] as String? ?? 'sincronizado',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      categoriaEdad: json['categoria_edad'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'arete': arete,
      'especie': especie,
      'sexo': sexo,
      'fecha_nacimiento': fechaNacimiento.toIso8601String().split('T').first,
      'nombre': nombre,
      'raza': raza,
      'padre': padreUid,
      'madre': madreUid,
      'observaciones': observaciones,
      'activo': activo,
    };
  }
}

class AnimalListModel {
  final String uid;
  final String arete;
  final String nombre;
  final String especie;
  final String sexo;
  final DateTime fechaNacimiento;
  final String? foto;
  final String? categoriaEdad;

  AnimalListModel({
    required this.uid,
    required this.arete,
    required this.nombre,
    required this.especie,
    required this.sexo,
    required this.fechaNacimiento,
    this.foto,
    this.categoriaEdad,
  });

  factory AnimalListModel.fromJson(Map<String, dynamic> json) {
    return AnimalListModel(
      uid: json['uid'] as String,
      arete: json['arete'] as String,
      nombre: json['nombre'] as String? ?? '',
      especie: json['especie'] as String,
      sexo: json['sexo'] as String,
      fechaNacimiento: DateTime.parse(json['fecha_nacimiento'] as String),
      foto: json['foto'] as String?,
      categoriaEdad: json['categoria_edad'] as String?,
    );
  }
}

class CandidatoModel {
  final String uid;
  final String arete;
  final String nombre;
  final String especie;
  final String sexo;

  CandidatoModel({
    required this.uid,
    required this.arete,
    required this.nombre,
    required this.especie,
    required this.sexo,
  });

  factory CandidatoModel.fromJson(Map<String, dynamic> json) {
    return CandidatoModel(
      uid: json['uid'] as String,
      arete: json['arete'] as String,
      nombre: json['nombre'] as String? ?? '',
      especie: json['especie'] as String,
      sexo: json['sexo'] as String,
    );
  }

  String get label => nombre.isNotEmpty ? '$arete - $nombre' : arete;
}

String categoriaEdadLabel(String? categoria) {
  switch (categoria) {
    case 'cría':
      return 'Cría';
    case 'tui_menor':
      return 'Tui Menor';
    case 'tui_mayor':
      return 'Tui Mayor';
    case 'borrego':
      return 'Borrego';
    case 'adulto':
      return 'Adulto';
    default:
      return '—';
  }
}

class ArbolNode {
  final String uid;
  final String arete;
  final String nombre;
  final String especie;
  final String sexo;
  final DateTime? fechaNacimiento;
  final String? foto;
  final ArbolNode? padre;
  final ArbolNode? madre;

  ArbolNode({
    required this.uid,
    required this.arete,
    required this.nombre,
    required this.especie,
    required this.sexo,
    this.fechaNacimiento,
    this.foto,
    this.padre,
    this.madre,
  });

  factory ArbolNode.fromJson(Map<String, dynamic> json) {
    return ArbolNode(
      uid: json['uid'] as String,
      arete: json['arete'] as String,
      nombre: json['nombre'] as String? ?? '',
      especie: json['especie'] as String,
      sexo: json['sexo'] as String,
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.tryParse(json['fecha_nacimiento'] as String)
          : null,
      foto: json['foto'] as String?,
      padre:
          json['padre'] != null ? ArbolNode.fromJson(json['padre']) : null,
      madre:
          json['madre'] != null ? ArbolNode.fromJson(json['madre']) : null,
    );
  }
}
