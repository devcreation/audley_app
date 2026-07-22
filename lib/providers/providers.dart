import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../data/api_client.dart';
import '../data/local_storage.dart';
import '../data/models/models.dart';

// ─── Dark Mode ──────────────────────────────────────────────
final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) => DarkModeNotifier());
class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(LocalStorage.getBool(AppConstants.darkModeKey));
  void toggle() { state = !state; LocalStorage.setBool(AppConstants.darkModeKey, state); }
}

// ─── Auth ───────────────────────────────────────────────────
enum AuthStatus { unknown, authenticated, unauthenticated }
class AuthState {
  final AuthStatus status;
  final bool isLoading;
  final String? error;
  AuthState({this.status = AuthStatus.unknown, this.isLoading = false, this.error});
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final _api = ApiClient();
  AuthNotifier(this._ref) : super(AuthState());

  Future<void> checkAuth() async {
    state = AuthState(status: AuthStatus.unknown, isLoading: true);
    final token = LocalStorage.getString(AppConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      state = AuthState(status: AuthStatus.authenticated);
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState(status: AuthStatus.unauthenticated, isLoading: true);
    final result = await _api.login(email, password);
    if (result['success'] == true) {
      final token = result['token']?.toString() ?? result['data']?['token']?.toString() ?? '';
      await LocalStorage.setString(AppConstants.tokenKey, token);
      state = AuthState(status: AuthStatus.authenticated);
      _ref.invalidate(siteDataProvider);
      return true;
    }
    state = AuthState(status: AuthStatus.unauthenticated, error: result['message']?.toString());
    return false;
  }

  Future<Map<String, dynamic>> register(String fullName, String jobTitle, String email, String mobile, String password) async {
    state = AuthState(status: AuthStatus.unauthenticated, isLoading: true);
    final result = await _api.register(fullName, jobTitle, email, mobile, password);
    state = AuthState(status: AuthStatus.unauthenticated);
    return result;
  }

  Future<void> logout() async {
    await LocalStorage.delete(AppConstants.tokenKey);
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

// ─── Site Data (fully dynamic from API) ─────────────────────
final siteDataProvider = FutureProvider<SiteData?>((ref) async {
  final api = ApiClient();
  final result = await api.getSiteData();
  if (result['success'] == true && result['data'] != null) {
    return SiteData.fromJson(Map<String, dynamic>.from(result['data']));
  }
  return null;
});
