import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static String get _baseUrl {
    const ip = String.fromEnvironment('API_HOST');
    if (ip.isNotEmpty) return 'http://$ip:8000/api/v1';
    return 'http://10.0.2.2:8000/api/v1';
  }
  static const String _accessKey = 'jwt_access';
  static const String _refreshKey = 'jwt_refresh';

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(_authInterceptor());
  }

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _accessKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final retryResponse = await _retry(error.requestOptions);
            return handler.resolve(retryResponse);
          }
        }
        handler.next(error);
      },
    );
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refresh = await _storage.read(key: _refreshKey);
      if (refresh == null) return false;
      final response = await Dio(BaseOptions(baseUrl: _baseUrl)).post(
        '/auth/refresh/',
        data: {'refresh': refresh},
      );
      await _storage.write(
          key: _accessKey, value: response.data['access'] as String);
      return true;
    } catch (_) {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
      return false;
    }
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await _storage.read(key: _accessKey);
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<void> saveTokens(
      String accessToken, String refreshToken) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessKey);

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: RequestOptions(path: ''),
      message: 'Respuesta inesperada del servidor',
    );
  }

  List<dynamic> _toList(dynamic data) {
    if (data is List<dynamic>) return data;
    throw DioException(
      requestOptions: RequestOptions(path: ''),
      message: 'Respuesta inesperada del servidor',
    );
  }

  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> data) async {
    final response = await _dio.post(path, data: data);
    return _toMap(response.data);
  }

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return _toMap(response.data);
  }

  Future<List<dynamic>> getList(String path,
      {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return _toList(response.data);
  }

  Future<Map<String, dynamic>> patch(
      String path, Map<String, dynamic> data) async {
    final response = await _dio.patch(path, data: data);
    return _toMap(response.data);
  }

  Future<Map<String, dynamic>> patchMultipart(
      String path, Map<String, dynamic> fields, String filePath) async {
    final formData = FormData.fromMap({
      ...fields,
      'foto': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.patch(path, data: formData);
    return _toMap(response.data);
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
  }

  Future<Response> download(String path, String savePath) async {
    return _dio.download(path, savePath);
  }
}
