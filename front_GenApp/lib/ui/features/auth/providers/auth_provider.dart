import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_genapp/data/models/user_model.dart';
import 'package:front_genapp/data/services/api_service.dart';
import 'package:front_genapp/data/repositories/auth_repository.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiServiceProvider));
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState());

  Future<void> checkAuth() async {
    final loggedIn = await _repo.isLoggedIn();
    if (loggedIn) {
      try {
        final user = await _repo.getPerfil();
        state = AuthState(user: user, isAuthenticated: true);
      } catch (_) {
        state = const AuthState();
      }
    }
  }

  Future<String?> register(
      String telefono, String nombre, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.register(telefono, nombre, password);
      await _repo.login(telefono, password);
      final user = await _repo.getPerfil();
      state = AuthState(user: user, isAuthenticated: true);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return _parseError(e);
    }
  }

  Future<String?> login(String telefono, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.login(telefono, password);
      final user = await _repo.getPerfil();
      state = AuthState(user: user, isAuthenticated: true);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return _parseError(e);
    }
  }

  Future<void> loadPerfil() async {
    try {
      final user = await _repo.getPerfil();
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  Future<String?> cambiarPlan(String plan) async {
    try {
      await _repo.cambiarPlan(plan);
      await loadPerfil();
      return null;
    } catch (e) {
      return _parseError(e);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  String _parseError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('401')) return 'Credenciales inválidas';
    if (msg.contains('400')) return 'Datos inválidos';
    return 'Error de conexión';
  }
}
