class VentaFibraListModel {
  final String uid;
  final String animalArete;
  final double kgVendidos;
  final double precioKg;
  final double? ingresoTotal;
  final String comprador;
  final DateTime fechaVenta;

  VentaFibraListModel({
    required this.uid,
    required this.animalArete,
    required this.kgVendidos,
    required this.precioKg,
    this.ingresoTotal,
    this.comprador = '',
    required this.fechaVenta,
  });

  factory VentaFibraListModel.fromJson(Map<String, dynamic> json) {
    return VentaFibraListModel(
      uid: json['uid'] as String,
      animalArete: json['animal_arete'] as String? ?? '',
      kgVendidos: double.tryParse(json['kg_vendidos'].toString()) ?? 0,
      precioKg: double.tryParse(json['precio_kg'].toString()) ?? 0,
      ingresoTotal: json['ingreso_total'] != null
          ? double.tryParse(json['ingreso_total'].toString())
          : null,
      comprador: json['comprador'] as String? ?? '',
      fechaVenta: DateTime.parse(json['fecha_venta'] as String),
    );
  }
}

class VentaFibraModel {
  final String? uid;
  final String animalUid;
  final String? produccionUid;
  final double kgVendidos;
  final double precioKg;
  final String comprador;
  final DateTime fechaVenta;

  VentaFibraModel({
    this.uid,
    required this.animalUid,
    this.produccionUid,
    required this.kgVendidos,
    required this.precioKg,
    this.comprador = '',
    required this.fechaVenta,
  });

  Map<String, dynamic> toJson() {
    return {
      'animal_write_uid': animalUid,
      'produccion_write_uid': produccionUid,
      'kg_vendidos': kgVendidos,
      'precio_kg': precioKg,
      'comprador': comprador,
      'fecha_venta': fechaVenta.toIso8601String().split('T').first,
    };
  }

  factory VentaFibraModel.fromJson(Map<String, dynamic> json) {
    return VentaFibraModel(
      uid: json['uid'] as String?,
      animalUid: json['animal_uid'] as String? ?? '',
      produccionUid: json['produccion_uid'] as String?,
      kgVendidos: double.tryParse(json['kg_vendidos'].toString()) ?? 0,
      precioKg: double.tryParse(json['precio_kg'].toString()) ?? 0,
      comprador: json['comprador'] as String? ?? '',
      fechaVenta: DateTime.parse(json['fecha_venta'] as String),
    );
  }
}
