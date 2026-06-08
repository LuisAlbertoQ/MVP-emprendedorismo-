import 'package:flutter_test/flutter_test.dart';
import 'package:front_genapp/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses complete JSON', () {
      final json = {
        'id': 1,
        'telefono': '999888777',
        'first_name': 'Juan',
        'plan': 'basico',
        'limite_animales': 150,
        'animales_count': 42,
        'generations_allowed': 3,
        'created_at': '2024-01-15T10:00:00Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 1);
      expect(user.telefono, '999888777');
      expect(user.firstName, 'Juan');
      expect(user.plan, 'basico');
      expect(user.limiteAnimales, 150);
      expect(user.animalesCount, 42);
      expect(user.generationsAllowed, 3);
      expect(user.createdAt, DateTime.utc(2024, 1, 15, 10, 0, 0));
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 1,
        'telefono': '999888777',
      };

      final user = UserModel.fromJson(json);

      expect(user.firstName, '');
      expect(user.plan, 'gratuito');
      expect(user.limiteAnimales, 20);
      expect(user.animalesCount, 0);
      expect(user.generationsAllowed, 2);
      expect(user.createdAt, isNull);
    });

    test('fromJson handles null created_at', () {
      final json = {
        'id': 1,
        'telefono': '999888777',
        'first_name': 'Juan',
        'plan': 'gratuito',
        'limite_animales': 20,
        'animales_count': 5,
        'generations_allowed': 2,
        'created_at': null,
      };

      final user = UserModel.fromJson(json);

      expect(user.createdAt, isNull);
    });
  });
}
