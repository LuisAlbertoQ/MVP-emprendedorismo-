import 'package:flutter_test/flutter_test.dart';
import 'package:front_genapp/data/models/animal_model.dart';
import 'package:front_genapp/ui/features/auth/providers/auth_provider.dart';
import 'package:front_genapp/ui/features/animales/providers/animal_provider.dart';

void main() {
  group('AuthState', () {
    test('default constructor values', () {
      const state = AuthState();

      expect(state.isLoading, false);
      expect(state.user, isNull);
      expect(state.error, isNull);
      expect(state.isAuthenticated, false);
    });

    test('copyWith overrides values correctly', () {
      const state = AuthState();
      final modified = state.copyWith(isAuthenticated: true, isLoading: true);

      expect(modified.isAuthenticated, true);
      expect(modified.isLoading, true);
      expect(modified.user, isNull);
      expect(modified.error, isNull);
    });

    test('copyWith sets error to null by default', () {
      const state = AuthState(error: 'old error');
      final modified = state.copyWith(isLoading: true);

      expect(modified.error, isNull);
    });
  });

  group('AnimalListState', () {
    test('default constructor values', () {
      const state = AnimalListState();

      expect(state.animales, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.page, 1);
      expect(state.hasMore, true);
      expect(state.filtroEspecie, isNull);
      expect(state.filtroSexo, isNull);
      expect(state.search, '');
    });

    test('copyWith preserves unset fields', () {
      const state = AnimalListState(filtroEspecie: 'alpaca', search: 'test');
      final modified = state.copyWith(isLoading: true);

      expect(modified.filtroEspecie, 'alpaca');
      expect(modified.search, 'test');
      expect(modified.isLoading, true);
      expect(modified.page, 1);
    });

    test('copyWith overrides specified fields', () {
      const state = AnimalListState();
      final modified = state.copyWith(
        animales: [
          AnimalListModel(
            uid: 'abc',
            arete: 'TEST-001',
            nombre: 'Test',
            especie: 'alpaca',
            sexo: 'macho',
            fechaNacimiento: DateTime(2024, 1, 1),
          ),
        ],
        isLoading: true,
        page: 2,
        hasMore: false,
        filtroEspecie: 'alpaca',
        filtroSexo: 'macho',
        search: 'test',
      );

      expect(modified.animales.length, 1);
      expect(modified.animales.first.arete, 'TEST-001');
      expect(modified.isLoading, true);
      expect(modified.page, 2);
      expect(modified.hasMore, false);
      expect(modified.filtroEspecie, 'alpaca');
      expect(modified.filtroSexo, 'macho');
      expect(modified.search, 'test');
    });

    test('constructor with filtros sets them correctly', () {
      const state = AnimalListState(
        filtroEspecie: 'llama',
        filtroSexo: 'hembra',
        search: 'busqueda',
      );

      expect(state.filtroEspecie, 'llama');
      expect(state.filtroSexo, 'hembra');
      expect(state.search, 'busqueda');
    });
  });
}
