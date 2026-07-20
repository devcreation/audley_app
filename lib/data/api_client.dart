import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

/// Singleton API client wrapping Dio with Bearer token auth,
/// error handling, and mobile client headers.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Client-Type': 'mobile',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: AppConstants.tokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  // ─── Auth ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _post(AppConstants.loginUrl, {
      'email': email,
      'password': password,
      'recaptcha_token': '', // Mobile skips reCAPTCHA
    });
    if (response['success'] == true && response['api_token'] != null) {
      await _secureStorage.write(
          key: AppConstants.tokenKey, value: response['api_token']);
    }
    return response;
  }

  Future<Map<String, dynamic>> register(
      String fullName, String email, String mobile, String password) async {
    return _post(AppConstants.registerUrl, {
      'full_name': fullName,
      'email': email,
      'mobile': mobile,
      'password': password,
      'confirm_password': password,
      'recaptcha_token': '',
    });
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return _post(AppConstants.forgotPasswordUrl, {
      'email': email,
      'recaptcha_token': '',
    });
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    return _post(AppConstants.verifyOtpUrl, {
      'email': email,
      'otp': otp,
    });
  }

  Future<Map<String, dynamic>> resetPassword(
      String resetToken, String newPassword) async {
    return _post(AppConstants.resetPasswordUrl, {
      'reset_token': resetToken,
      'new_password': newPassword,
      'confirm_password': newPassword,
      'recaptcha_token': '',
    });
  }

  Future<void> logout() async {
    try {
      await _post(AppConstants.logoutUrl, {});
    } catch (_) {
      // Logout even if API call fails
    }
    await _secureStorage.delete(key: AppConstants.tokenKey);
    await _secureStorage.delete(key: AppConstants.userKey);
  }

  // ─── Content ──────────────────────────────────────────────

  Future<Map<String, dynamic>> getSiteData({String? etag}) async {
    final headers = <String, dynamic>{};
    if (etag != null) headers['If-None-Match'] = etag;
    return _get(AppConstants.siteDataUrl, headers: headers);
  }

  Future<Map<String, dynamic>> getAppConfig() async {
    return _get(AppConstants.appConfigUrl);
  }

  // ─── Forms ────────────────────────────────────────────────

  Future<Map<String, dynamic>> getParticipantInfo() async {
    return _get(AppConstants.getParticipantUrl);
  }

  Future<Map<String, dynamic>> submitParticipantInfo(
      Map<String, dynamic> data) async {
    data['recaptcha_token'] = '';
    return _post(AppConstants.submitParticipantUrl, data);
  }

  Future<Map<String, dynamic>> getOptionalTours() async {
    return _get(AppConstants.getToursUrl);
  }

  Future<Map<String, dynamic>> submitOptionalTours(
      Map<String, dynamic> data) async {
    data['recaptcha_token'] = '';
    return _post(AppConstants.submitToursUrl, data);
  }

  Future<Map<String, dynamic>> getParticipants() async {
    return _get(AppConstants.getParticipantsUrl);
  }

  // ─── Notifications ────────────────────────────────────────

  Future<void> registerFcmToken(String fcmToken, String platform) async {
    await _post(AppConstants.registerFcmUrl, {
      'fcm_token': fcmToken,
      'platform': platform,
    });
  }

  // ─── Token check ──────────────────────────────────────────

  Future<bool> hasValidToken() async {
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    if (token == null || token.isEmpty) return false;
    try {
      final result = await getParticipantInfo();
      return result['success'] == true || result['data'] != null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) return false;
      // Network error — assume token is valid (offline mode)
      return true;
    }
  }

  // ─── Private helpers ──────────────────────────────────────

  Future<Map<String, dynamic>> _get(String url,
      {Map<String, dynamic>? headers}) async {
    try {
      final response =
          await _dio.get(url, options: Options(headers: headers));
      if (response.statusCode == 304) {
        return {'success': true, 'not_modified': true};
      }
      return response.data is Map<String, dynamic>
          ? response.data
          : {'success': false, 'message': 'Invalid response'};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> _post(
      String url, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(url, data: data);
      return response.data is Map<String, dynamic>
          ? response.data
          : {'success': false, 'message': 'Invalid response'};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Map<String, dynamic> _handleDioError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      return e.response!.data;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return {
        'success': false,
        'message': 'Connection timed out. Please check your internet.'
      };
    }
    if (e.type == DioExceptionType.connectionError) {
      return {
        'success': false,
        'message': 'No internet connection. Please try again.'
      };
    }
    return {
      'success': false,
      'message': 'Something went wrong. Please try again.'
    };
  }
}
