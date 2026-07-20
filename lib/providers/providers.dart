import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';
import '../data/api_client.dart';
import '../data/local_storage.dart';
import '../data/models/models.dart';

// ─── API Client ─────────────────────────────────────────────
final apiClientProvider = Provider((_) => ApiClient());

// ─── Dark Mode ──────────────────────────────────────────────
final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier();
});

class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(LocalStorage.getBool(AppConstants.darkModeKey)) ;

  void toggle() {
    state = !state;
    LocalStorage.setBool(AppConstants.darkModeKey, state);
  }
}

// ─── Auth State ─────────────────────────────────────────────
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? error,
    bool? isLoading,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
        isLoading: isLoading ?? this.isLoading,
      );
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final _secureStorage = const FlutterSecureStorage();

  AuthNotifier(this._ref) : super(const AuthState());

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final api = _ref.read(apiClientProvider);
      final valid = await api.hasValidToken();
      if (valid) {
        // Try to read cached user
        final userJson =
            await _secureStorage.read(key: AppConstants.userKey);
        AppUser? user;
        if (userJson != null) {
          user = AppUser.fromJson(jsonDecode(userJson));
        }
        state = state.copyWith(
            status: AuthStatus.authenticated, user: user, isLoading: false);
      } else {
        state = state.copyWith(
            status: AuthStatus.unauthenticated, isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(
          status: AuthStatus.unauthenticated, isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final api = _ref.read(apiClientProvider);
    final result = await api.login(email, password);

    if (result['success'] == true) {
      final user = AppUser.fromJson(result['user'] ?? {});
      await _secureStorage.write(
          key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      state = state.copyWith(
          status: AuthStatus.authenticated, user: user, isLoading: false);
      return true;
    } else {
      state = state.copyWith(
          isLoading: false, error: result['message'] ?? 'Login failed');
      return false;
    }
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String mobile, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final api = _ref.read(apiClientProvider);
    final result = await api.register(name, email, mobile, password);
    state = state.copyWith(isLoading: false);
    return result;
  }

  Future<void> logout() async {
    final api = _ref.read(apiClientProvider);
    await api.logout();
    await LocalStorage.delete(AppConstants.siteDataCacheKey);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// ─── Site Content ───────────────────────────────────────────
class ContentState {
  final SiteData? data;
  final bool isLoading;
  final String? error;
  final bool isFromCache;

  const ContentState({
    this.data,
    this.isLoading = false,
    this.error,
    this.isFromCache = false,
  });

  ContentState copyWith({
    SiteData? data,
    bool? isLoading,
    String? error,
    bool? isFromCache,
  }) =>
      ContentState(
        data: data ?? this.data,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isFromCache: isFromCache ?? this.isFromCache,
      );
}

final contentProvider =
    StateNotifierProvider<ContentNotifier, ContentState>((ref) {
  return ContentNotifier(ref);
});

class ContentNotifier extends StateNotifier<ContentState> {
  final Ref _ref;

  ContentNotifier(this._ref) : super(const ContentState());

  Future<void> loadContent({bool forceRefresh = false}) async {
    // Try cache first
    if (!forceRefresh && state.data == null) {
      final cached = LocalStorage.get(AppConstants.siteDataCacheKey);
      if (cached != null) {
        try {
          final siteData = SiteData.fromJson(Map<String, dynamic>.from(cached));
          state = state.copyWith(data: siteData, isFromCache: true);
        } catch (_) {}
      }
    }

    state = state.copyWith(isLoading: true, error: null);
    final api = _ref.read(apiClientProvider);

    try {
      final etag = forceRefresh
          ? null
          : LocalStorage.getString(AppConstants.etagKey);
      final result = await api.getSiteData(etag: etag);

      if (result['not_modified'] == true) {
        // Cache is still valid
        state = state.copyWith(isLoading: false);
        return;
      }

      if (result['success'] == true && result['data'] != null) {
        final siteData =
            SiteData.fromJson(Map<String, dynamic>.from(result['data']));
        await LocalStorage.save(
            AppConstants.siteDataCacheKey, result['data']);
        if (result['etag'] != null) {
          await LocalStorage.setString(
              AppConstants.etagKey, result['etag']);
        }
        state = ContentState(data: siteData, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: state.data == null ? (result['message'] ?? 'Failed to load') : null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: state.data == null ? 'Connection error' : null,
      );
    }
  }
}

// ─── Participants Directory ─────────────────────────────────
final participantsProvider =
    FutureProvider.autoDispose<List<Participant>>((ref) async {
  final api = ref.read(apiClientProvider);
  final result = await api.getParticipants();
  if (result['success'] == true && result['data'] != null) {
    return (result['data'] as List)
        .map((p) => Participant.fromJson(Map<String, dynamic>.from(p)))
        .toList();
  }
  return [];
});

// ─── Bottom Nav ─────────────────────────────────────────────
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// ─── Scaffold key for drawer/snackbar ───────────────────────
final scaffoldKeyProvider =
    Provider((ref) => GlobalKey<ScaffoldMessengerState>());
