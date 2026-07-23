import 'package:dio/dio.dart';
import '../core/constants.dart';
import 'local_storage.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBase,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json', 'X-Client-Type': 'mobile'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = LocalStorage.getString(AppConstants.tokenKey);
        if (token != null && token.isNotEmpty) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ));
  }

  // ─── Auth ─────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final r = await _dio.post('/auth.php', data: {'action': 'login', 'email': email, 'password': password});
      return Map<String, dynamic>.from(r.data);
    } catch (e) { return _err(e); }
  }

  Future<Map<String, dynamic>> register(String fullName, String jobTitle, String email, String mobile, String password) async {
    try {
      final r = await _dio.post('/auth.php', data: {'action': 'register', 'full_name': fullName, 'job_title': jobTitle, 'email': email, 'mobile': mobile, 'password': password, 'confirm_password': password});
      return Map<String, dynamic>.from(r.data);
    } catch (e) { return _err(e); }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final r = await _dio.post('/auth.php', data: {'action': 'forgot_password', 'email': email});
      return Map<String, dynamic>.from(r.data);
    } catch (e) { return _err(e); }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final r = await _dio.post('/auth.php', data: {'action': 'verify_otp', 'email': email, 'otp': otp});
      return Map<String, dynamic>.from(r.data);
    } catch (e) { return _err(e); }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String token, String password) async {
    try {
      final r = await _dio.post('/auth.php', data: {'action': 'reset_password', 'email': email, 'reset_token': token, 'new_password': password});
      return Map<String, dynamic>.from(r.data);
    } catch (e) { return _err(e); }
  }

  // ─── App Config (NO AUTH - for login/register branding) ───
  Future<Map<String, dynamic>> getAppConfig() async {
    try {
      final r = await _dio.get('/content.php', queryParameters: {'action': 'get_app_config'});
      return Map<String, dynamic>.from(r.data);
    } catch (e) { return _err(e); }
  }

  // ─── Content ──────────────────────────────────────
  Future<Map<String, dynamic>> getSiteData() async {
    try {
      final r = await _dio.get('/content.php', queryParameters: {'action': 'get_site_data'});
      return Map<String, dynamic>.from(r.data);
    } catch (e) { return _err(e); }
  }

  // ─── Form Config (dynamic participant + tour options) ────
  Future<Map<String, dynamic>> getFormConfig() async {
    try {
      final r = await _dio.get('/forms.php', queryParameters: {'action': 'get_form_config'});
      return Map<String, dynamic>.from(r.data);
    } catch (e) { return _err(e); }
  }

  // ─── Tour Availability ────────────────────────────
  Future<Map<String, dynamic>> getTourAvailability() async {
    try {
      final r = await _dio.get('/forms.php', queryParameters: {'action': 'get_tour_availability'});
      return Map<String, dynamic>.from(r.data);
    } catch (e) { return _err(e); }
  }

  // ─── Forms ────────────────────────────────────────
  Future<Map<String, dynamic>> getParticipantInfo() async {
    try {
      final r = await _dio.get('/forms.php', queryParameters: {'action': 'get_participant_info'});
      return Map<String, dynamic>.from(r.data);
    } catch (e) { return _err(e); }
  }

  Future<Map<String, dynamic>> submitParticipantInfo(Map<String, dynamic> data) async {
    try {
      final body = Map<String, dynamic>.from(data);
      body['action'] = 'submit_participant_info';
      final r = await _dio.post('/forms.php', data: body);
      return Map<String, dynamic>.from(r.data);
    } catch (e) { return _err(e); }
  }

  Future<Map<String, dynamic>> getOptionalTours() async {
    try {
      final r = await _dio.get('/forms.php', queryParameters: {'action': 'get_optional_tours'});
      return Map<String, dynamic>.from(r.data);
    } catch (e) { return _err(e); }
  }

  Future<Map<String, dynamic>> submitOptionalTours(Map<String, dynamic> data) async {
    try {
      final body = Map<String, dynamic>.from(data);
      body['action'] = 'submit_optional_tours';
      final r = await _dio.post('/forms.php', data: body);
      return Map<String, dynamic>.from(r.data);
    } catch (e) { return _err(e); }
  }

  // ─── Participant Directory ────────────────────────
  Future<Map<String, dynamic>> getParticipants() async {
    try {
      final r = await _dio.get('/forms.php', queryParameters: {'action': 'get_participants'});
      return Map<String, dynamic>.from(r.data);
    } catch (e) { return _err(e); }
  }

  // ─── Catch ANY error (DioException, TypeError, FormatException, etc.) ───
  Map<String, dynamic> _err(Object e) {
    if (e is DioException) {
      final msg = e.response?.data is Map ? (e.response?.data['message'] ?? e.message ?? 'Network error') : (e.message ?? 'Network error');
      return {'success': false, 'message': msg.toString()};
    }
    return {'success': false, 'message': e.toString()};
  }
}
