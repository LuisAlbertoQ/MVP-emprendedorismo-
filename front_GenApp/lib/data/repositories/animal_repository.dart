import 'package:front_genapp/data/models/animal_model.dart';
import 'package:front_genapp/data/services/api_service.dart';

class AnimalRepository {
  final ApiService _api;

  AnimalRepository(this._api);

  Future<List<AnimalListModel>> getAnimales({
    String? especie,
    String? sexo,
    String? search,
    int page = 1,
  }) async {
    final params = <String, dynamic>{'page': page};
    if (especie != null) params['especie'] = especie;
    if (sexo != null) params['sexo'] = sexo;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final data = await _api.get('/animales/', queryParameters: params);
    final results = data['results'] as List<dynamic>;
    return results
        .map((e) => AnimalListModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AnimalModel> getAnimal(String uid) async {
    final data = await _api.get('/animales/$uid/');
    return AnimalModel.fromJson(data);
  }

  Future<AnimalModel> createAnimal(AnimalModel animal) async {
    final data = await _api.post('/animales/', animal.toJson());
    return AnimalModel.fromJson(data);
  }

  Future<AnimalModel> updateAnimal(String uid, AnimalModel animal) async {
    final data = await _api.patch('/animales/$uid/', animal.toJson());
    return AnimalModel.fromJson(data);
  }

  Future<void> deleteAnimal(String uid) async {
    await _api.delete('/animales/$uid/');
  }

  Future<ArbolNode> getArbol(String uid) async {
    final data = await _api.get('/animales/$uid/arbol/');
    return ArbolNode.fromJson(data);
  }

  Future<List<CandidatoModel>> getCandidatos() async {
    final data = await _api.getList('/animales/candidatos/');
    return data
        .map((e) => CandidatoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getResumen() async {
    return _api.get('/animales/resumen/');
  }

  Future<void> download(String path, String savePath) async {
    await _api.download(path, savePath);
  }

  Future<void> subirFoto(String uid, String filePath) async {
    await _api.patchMultipart('/animales/$uid/', {}, filePath);
  }
}
