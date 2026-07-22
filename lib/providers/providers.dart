import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api_client.dart';
import '../data/local_storage.dart';
import '../data/models/models.dart';

// ─── Dark Mode ──────────────────────────────────────────────
final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) => DarkModeNotifier());
class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(LocalStorage.getDarkMode());
  void toggle() { state = !state; LocalStorage.setDarkMode(state); }
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
    final token = LocalStorage.getToken();
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
      final token = result['token'] ?? result['data']?['token'] ?? '';
      await LocalStorage.setToken(token);
      state = AuthState(status: AuthStatus.authenticated);
      _ref.invalidate(siteDataProvider);
      return true;
    }
    state = AuthState(status: AuthStatus.unauthenticated, error: result['message']);
    return false;
  }

  Future<void> logout() async {
    await LocalStorage.clearToken();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

// ─── Site Data (fully dynamic from API) ─────────────────────
final siteDataProvider = FutureProvider<SiteData?>((ref) async {
  final api = ApiClient();
  final result = await api.getSiteData();
  if (result['success'] == true && result['data'] != null) {
    return SiteData.fromJson(result['data']);
  }
  return null;
});
