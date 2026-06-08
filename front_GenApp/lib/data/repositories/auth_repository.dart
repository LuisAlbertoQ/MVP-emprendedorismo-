import 'package:front_genapp/data/models/user_model.dart';
import 'package:front_genapp/data/services/api_service.dart';

class AuthRepository {
  final ApiService _api;

  AuthRepository(this._api);

  Future<void> register(String telefono, String nombre, String password) async {
    await _api.post('/auth/register/', {
      'telefono': telefono,
      'nombre': nombre,
      'password': password,
    });
  }

  Future<void> login(String telefono, String password) async {
    final data = await _api.post('/auth/login/', {
      'telefono': telefono,
      'password': password,
    });
    await _api.saveTokens(
      data['access'] as String,
      data['refresh'] as String,
    );
  }

  Future<UserModel> getPerfil() async {
    final data = await _api.get('/auth/perfil/');
    return UserModel.fromJson(data);
  }

  Future<void> cambiarPlan(String plan) async {
    await _api.post('/auth/cambiar-plan/', {'plan': plan});
  }

  Future<bool> isLoggedIn() async {
    final token = await _api.getAccessToken();
    return token != null;
  }

  Future<void> logout() async {
    await _api.clearTokens();
  }
}
