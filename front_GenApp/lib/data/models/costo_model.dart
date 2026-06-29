class CostoListModel {
  final String uid;
  final String animalArete;
  final String tipo;
  final double monto;
  final DateTime fecha;
  final String descripcion;

  CostoListModel({
    required this.uid,
    required this.animalArete,
    required this.tipo,
    required this.monto,
    required this.fecha,
    this.descripcion = '',
  });

  factory CostoListModel.fromJson(Map<String, dynamic> json) {
    return CostoListModel(
      uid: json['uid'] as String,
      animalArete: json['animal_arete'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      monto: double.tryParse(json['monto'].toString()) ?? 0,
      fecha: DateTime.parse(json['fecha'] as String),
      descripcion: json['descripcion'] as String? ?? '',
    );
  }
}

class CostoModel {
  final String? uid;
  final String animalUid;
  final String tipo;
  final double monto;
  final DateTime fecha;
  final String descripcion;

  CostoModel({
    this.uid,
    required this.animalUid,
    required this.tipo,
    required this.monto,
    required this.fecha,
    this.descripcion = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'animal_write_uid': animalUid,
      'tipo': tipo,
      'monto': monto,
      'fecha': fecha.toIso8601String().split('T').first,
      'descripcion': descripcion,
    };
  }

  factory CostoModel.fromJson(Map<String, dynamic> json) {
    return CostoModel(
      uid: json['uid'] as String?,
      animalUid: json['animal_uid'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      monto: double.tryParse(json['monto'].toString()) ?? 0,
      fecha: DateTime.parse(json['fecha'] as String),
      descripcion: json['descripcion'] as String? ?? '',
    );
  }
}

String tipoCostoLabel(String value) {
  switch (value) {
    case 'alimentacion':
      return 'Alimentación';
    case 'sanidad':
      return 'Sanidad';
    case 'esquila':
      return 'Esquila';
    case 'transporte':
      return 'Transporte';
    case 'otro':
      return 'Otro';
    default:
      return value;
  }
}
