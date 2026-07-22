import 'package:dio/dio.dart';
import '../core/constants.dart';
import 'local_storage.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json', 'X-Client-Type': 'mobile'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = LocalStorage.getToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ));
  }

  // ─── Auth ─────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final r = await _dio.post('/auth.php', data: {'action': 'login', 'email': email, 'password': password});
      return r.data;
    } on DioException catch (e) { return _err(e); }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final r = await _dio.post('/auth.php', data: {'action': 'register', ...data});
      return r.data;
    } on DioException catch (e) { return _err(e); }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final r = await _dio.post('/auth.php', data: {'action': 'forgot_password', 'email': email});
      return r.data;
    } on DioException catch (e) { return _err(e); }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final r = await _dio.post('/auth.php', data: {'action': 'verify_otp', 'email': email, 'otp': otp});
      return r.data;
    } on DioException catch (e) { return _err(e); }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String token, String password) async {
    try {
      final r = await _dio.post('/auth.php', data: {'action': 'reset_password', 'email': email, 'reset_token': token, 'new_password': password});
      return r.data;
    } on DioException catch (e) { return _err(e); }
  }

  // ─── Content ──────────────────────────────────────
  Future<Map<String, dynamic>> getSiteData() async {
    try {
      final r = await _dio.get('/content.php', queryParameters: {'action': 'get_site_data'});
      return r.data;
    } on DioException catch (e) { return _err(e); }
  }

  Future<Map<String, dynamic>> getUpdates() async {
    try {
      final r = await _dio.get('/content.php', queryParameters: {'action': 'get_updates'});
      return r.data;
    } on DioException catch (e) { return _err(e); }
  }

  // ─── Tour Availability ─────────────────────────────
  Future<Map<String, dynamic>> getTourAvailability() async {
    try {
      final r = await _dio.get('/forms.php', queryParameters: {'action': 'get_tour_availability'});
      return r.data;
    } on DioException catch (e) { return _err(e); }
  }

  // ─── Forms ────────────────────────────────────────
  Future<Map<String, dynamic>> getParticipantInfo() async {
    try {
      final r = await _dio.get('/forms.php', queryParameters: {'action': 'get_participant_info'});
      return r.data;
    } on DioException catch (e) { return _err(e); }
  }

  Future<Map<String, dynamic>> submitParticipantInfo(Map<String, dynamic> data) async {
    try {
      final r = await _dio.post('/forms.php', data: {'action': 'submit_participant_info', ...data});
      return r.data;
    } on DioException catch (e) { return _err(e); }
  }

  Future<Map<String, dynamic>> getOptionalTours() async {
    try {
      final r = await _dio.get('/forms.php', queryParameters: {'action': 'get_optional_tours'});
      return r.data;
    } on DioException catch (e) { return _err(e); }
  }

  Future<Map<String, dynamic>> submitOptionalTours(Map<String, dynamic> data) async {
    try {
      final r = await _dio.post('/forms.php', data: {'action': 'submit_optional_tours', ...data});
      return r.data;
    } on DioException catch (e) { return _err(e); }
  }

  Map<String, dynamic> _err(DioException e) {
    final msg = e.response?.data?['message'] ?? e.message ?? 'Network error';
    return {'success': false, 'message': msg};
  }
}
