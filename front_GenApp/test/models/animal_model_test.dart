import 'package:flutter_test/flutter_test.dart';
import 'package:front_genapp/data/models/animal_model.dart';

void main() {
  group('AnimalModel', () {
    test('fromJson parses complete JSON correctly', () {
      final json = {
        'uid': 'abc-123',
        'arete': 'HIJO-001',
        'especie': 'alpaca',
        'sexo': 'macho',
        'fecha_nacimiento': '2024-01-15',
        'nombre': 'Tormenta',
        'raza': 'Huacaya',
        'padre': 'PADRE-001 - Relámpago',
        'madre': 'MADRE-001 - Blanca',
        'padre_uid': 'padre-uid',
        'madre_uid': 'madre-uid',
        'foto': null,
        'observaciones': 'Sano',
        'activo': true,
        'sync_status': 'sincronizado',
        'created_at': '2024-01-15T10:00:00Z',
        'updated_at': '2024-06-01T10:00:00Z',
        'categoria_edad': 'adulto',
      };

      final model = AnimalModel.fromJson(json);

      expect(model.uid, 'abc-123');
      expect(model.arete, 'HIJO-001');
      expect(model.especie, 'alpaca');
      expect(model.sexo, 'macho');
      expect(model.fechaNacimiento, DateTime(2024, 1, 15));
      expect(model.nombre, 'Tormenta');
      expect(model.raza, 'Huacaya');
      expect(model.padre, 'PADRE-001 - Relámpago');
      expect(model.madre, 'MADRE-001 - Blanca');
      expect(model.padreUid, 'padre-uid');
      expect(model.madreUid, 'madre-uid');
      expect(model.foto, isNull);
      expect(model.observaciones, 'Sano');
      expect(model.activo, true);
      expect(model.syncStatus, 'sincronizado');
      expect(model.categoriaEdad, 'adulto');
      expect(model.createdAt, DateTime.utc(2024, 1, 15, 10, 0, 0));
      expect(model.updatedAt, DateTime.utc(2024, 6, 1, 10, 0, 0));
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'uid': 'abc-123',
        'arete': 'HIJO-001',
        'especie': 'alpaca',
        'sexo': 'macho',
        'fecha_nacimiento': '2024-01-15',
      };

      final model = AnimalModel.fromJson(json);

      expect(model.uid, 'abc-123');
      expect(model.nombre, '');
      expect(model.raza, '');
      expect(model.padre, isNull);
      expect(model.madre, isNull);
      expect(model.padreUid, isNull);
      expect(model.madreUid, isNull);
      expect(model.foto, isNull);
      expect(model.observaciones, '');
      expect(model.activo, true);
      expect(model.syncStatus, 'sincronizado');
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });

    test('toJson returns correct map', () {
      final model = AnimalModel(
        uid: 'abc-123',
        arete: 'HIJO-001',
        especie: 'alpaca',
        sexo: 'macho',
        fechaNacimiento: DateTime(2024, 1, 15),
        nombre: 'Tormenta',
        raza: 'Huacaya',
        padreUid: 'padre-uid',
        madreUid: 'madre-uid',
        observaciones: 'Sano',
        activo: true,
      );

      final json = model.toJson();

      expect(json['arete'], 'HIJO-001');
      expect(json['especie'], 'alpaca');
      expect(json['sexo'], 'macho');
      expect(json['fecha_nacimiento'], '2024-01-15');
      expect(json['nombre'], 'Tormenta');
      expect(json['raza'], 'Huacaya');
      expect(json['padre'], 'padre-uid');
      expect(json['madre'], 'madre-uid');
      expect(json['observaciones'], 'Sano');
      expect(json['activo'], true);
    });

    test('toJson includes null parent UIDs', () {
      final model = AnimalModel(
        uid: 'abc-123',
        arete: 'HIJO-001',
        especie: 'alpaca',
        sexo: 'macho',
        fechaNacimiento: DateTime(2024, 1, 15),
      );

      final json = model.toJson();

      expect(json.containsKey('padre'), true);
      expect(json['padre'], isNull);
      expect(json.containsKey('madre'), true);
      expect(json['madre'], isNull);
    });
  });

  group('AnimalListModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'uid': 'abc-123',
        'arete': 'HIJO-001',
        'nombre': 'Tormenta',
        'especie': 'alpaca',
        'sexo': 'macho',
        'fecha_nacimiento': '2024-01-15',
        'foto': null,
        'categoria_edad': 'tui_mayor',
      };

      final model = AnimalListModel.fromJson(json);

      expect(model.uid, 'abc-123');
      expect(model.arete, 'HIJO-001');
      expect(model.nombre, 'Tormenta');
      expect(model.especie, 'alpaca');
      expect(model.sexo, 'macho');
      expect(model.fechaNacimiento, DateTime(2024, 1, 15));
      expect(model.foto, isNull);
      expect(model.categoriaEdad, 'tui_mayor');
    });

    test('fromJson handles missing nombre', () {
      final json = {
        'uid': 'abc-123',
        'arete': 'HIJO-001',
        'especie': 'alpaca',
        'sexo': 'macho',
        'fecha_nacimiento': '2024-01-15',
      };

      final model = AnimalListModel.fromJson(json);

      expect(model.nombre, '');
    });
  });

  group('CandidatoModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'uid': 'abc-123',
        'arete': 'PADRE-001',
        'nombre': 'Relámpago',
        'especie': 'alpaca',
        'sexo': 'macho',
      };

      final model = CandidatoModel.fromJson(json);

      expect(model.uid, 'abc-123');
      expect(model.arete, 'PADRE-001');
      expect(model.nombre, 'Relámpago');
      expect(model.especie, 'alpaca');
      expect(model.sexo, 'macho');
    });

    test('label returns arete - nombre when nombre is present', () {
      final model = CandidatoModel(
        uid: 'abc',
        arete: 'PADRE-001',
        nombre: 'Relámpago',
        especie: 'alpaca',
        sexo: 'macho',
      );

      expect(model.label, 'PADRE-001 - Relámpago');
    });

    test('label returns arete only when nombre is empty', () {
      final model = CandidatoModel(
        uid: 'abc',
        arete: 'PADRE-001',
        nombre: '',
        especie: 'alpaca',
        sexo: 'macho',
      );

      expect(model.label, 'PADRE-001');
    });
  });

  group('ArbolNode', () {
    test('fromJson parses flat node', () {
      final json = {
        'uid': 'abc',
        'arete': 'HIJO-001',
        'nombre': 'Tormenta',
        'especie': 'alpaca',
        'sexo': 'macho',
        'fecha_nacimiento': '2024-01-15',
        'foto': null,
      };

      final node = ArbolNode.fromJson(json);

      expect(node.uid, 'abc');
      expect(node.arete, 'HIJO-001');
      expect(node.nombre, 'Tormenta');
      expect(node.especie, 'alpaca');
      expect(node.sexo, 'macho');
      expect(node.fechaNacimiento, DateTime(2024, 1, 15));
      expect(node.padre, isNull);
      expect(node.madre, isNull);
    });

    test('fromJson parses node with parents', () {
      final json = {
        'uid': 'abc',
        'arete': 'HIJO-001',
        'nombre': 'Tormenta',
        'especie': 'alpaca',
        'sexo': 'macho',
        'fecha_nacimiento': '2024-01-15',
        'foto': null,
        'padre': {
          'uid': 'padre-uid',
          'arete': 'PADRE-001',
          'nombre': 'Relámpago',
          'especie': 'alpaca',
          'sexo': 'macho',
        },
        'madre': {
          'uid': 'madre-uid',
          'arete': 'MADRE-001',
          'nombre': 'Blanca',
          'especie': 'alpaca',
          'sexo': 'hembra',
        },
      };

      final node = ArbolNode.fromJson(json);

      expect(node.padre, isNotNull);
      expect(node.padre!.arete, 'PADRE-001');
      expect(node.padre!.nombre, 'Relámpago');
      expect(node.madre, isNotNull);
      expect(node.madre!.arete, 'MADRE-001');
      expect(node.madre!.nombre, 'Blanca');
    });

    test('fromJson handles null fecha_nacimiento', () {
      final json = {
        'uid': 'abc',
        'arete': 'HIJO-001',
        'nombre': 'Tormenta',
        'especie': 'alpaca',
        'sexo': 'macho',
        'fecha_nacimiento': null,
      };

      final node = ArbolNode.fromJson(json);

      expect(node.fechaNacimiento, isNull);
    });
  });
}
