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
  final String estado;
  final DateTime? fechaEstado;
  final String motivoEstado;
  final double? pesoNacimientoKg;
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
    this.estado = 'VIVO',
    this.fechaEstado,
    this.motivoEstado = '',
    this.pesoNacimientoKg,
    this.syncStatus = 'sincronizado',
    this.createdAt,
    this.updatedAt,
    this.categoriaEdad,
  });

  factory AnimalModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        final dt = DateTime.tryParse(value);
        if (dt != null) return dt;
      }
      return null;
    }

    return AnimalModel(
      uid: json['uid'] as String? ?? '',
      arete: json['arete'] as String? ?? '',
      especie: json['especie'] as String? ?? 'alpaca',
      sexo: json['sexo'] as String? ?? 'macho',
      fechaNacimiento: parseDate(json['fecha_nacimiento']) ?? DateTime.now(),
      nombre: json['nombre'] as String? ?? '',
      raza: json['raza'] as String? ?? '',
      padre: json['padre'] as String?,
      madre: json['madre'] as String?,
      padreUid: json['padre_uid'] as String?,
      madreUid: json['madre_uid'] as String?,
      foto: json['foto'] as String?,
      observaciones: json['observaciones'] as String? ?? '',
      estado: json['estado'] as String? ?? 'VIVO',
      fechaEstado: parseDate(json['fecha_estado']),
      motivoEstado: json['motivo_estado'] as String? ?? '',
      pesoNacimientoKg: json['peso_nacimiento_kg'] != null
          ? double.tryParse(json['peso_nacimiento_kg'].toString())
          : null,
      syncStatus: json['sync_status'] as String? ?? 'sincronizado',
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
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
      'estado': estado,
      'motivo_estado': motivoEstado,
      'peso_nacimiento_kg': pesoNacimientoKg,
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
  final String estado;

  AnimalListModel({
    required this.uid,
    required this.arete,
    required this.nombre,
    required this.especie,
    required this.sexo,
    required this.fechaNacimiento,
    this.foto,
    this.categoriaEdad,
    this.estado = 'VIVO',
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
      estado: json['estado'] as String? ?? 'VIVO',
    );
  }
}

class CandidatoModel {
  final String uid;
  final String arete;
  final String nombre;
  final String especie;
  final String sexo;
  final String? categoriaEdad;

  CandidatoModel({
    required this.uid,
    required this.arete,
    required this.nombre,
    required this.especie,
    required this.sexo,
    this.categoriaEdad,
  });

  factory CandidatoModel.fromJson(Map<String, dynamic> json) {
    return CandidatoModel(
      uid: json['uid'] as String,
      arete: json['arete'] as String,
      nombre: json['nombre'] as String? ?? '',
      especie: json['especie'] as String,
      sexo: json['sexo'] as String,
      categoriaEdad: json['categoria_edad'] as String?,
    );
  }

  String get label => nombre.isNotEmpty ? '$arete - $nombre' : arete;
}

String estadoLabel(String estado) {
  switch (estado) {
    case 'VIVO':
      return 'Vivo';
    case 'VENDIDO':
      return 'Vendido';
    case 'MUERTO':
      return 'Muerto';
    default:
      return estado;
  }
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
  final String estado;
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
    this.estado = 'VIVO',
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
      estado: json['estado'] as String? ?? 'VIVO',
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
