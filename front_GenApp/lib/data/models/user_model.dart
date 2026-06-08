class UserModel {
  final int id;
  final String telefono;
  final String firstName;
  final String plan;
  final int limiteAnimales;
  final int animalesCount;
  final int generationsAllowed;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.telefono,
    required this.firstName,
    required this.plan,
    required this.limiteAnimales,
    required this.animalesCount,
    required this.generationsAllowed,
    this.createdAt,
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
    );
  }
}
