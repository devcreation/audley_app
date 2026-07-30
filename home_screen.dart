/// App-wide constants and configuration.
/// All API URLs point to the live website — the single source of truth.
class AppConstants {
  AppConstants._();

  // ─── API ──────────────────────────────────────────────────
  static const String baseUrl =
      'https://www.distantfrontiers.in/audleyachievers';
  static const String apiBase = '$baseUrl/api';

  // Auth endpoints
  static const String loginUrl = '$apiBase/auth.php?action=login';
  static const String registerUrl = '$apiBase/auth.php?action=register';
  static const String forgotPasswordUrl =
      '$apiBase/auth.php?action=forgot_password';
  static const String verifyOtpUrl = '$apiBase/auth.php?action=verify_otp';
  static const String resetPasswordUrl =
      '$apiBase/auth.php?action=reset_password';
  static const String logoutUrl = '$apiBase/auth.php?action=logout';

  // Content endpoints
  static const String siteDataUrl =
      '$apiBase/content.php?action=get_site_data';
  static const String updatesUrl = '$apiBase/content.php?action=get_updates';
  static const String appConfigUrl =
      '$apiBase/content.php?action=get_app_config';

  // Form endpoints
  static const String submitParticipantUrl =
      '$apiBase/forms.php?action=submit_participant';
  static const String submitToursUrl =
      '$apiBase/forms.php?action=submit_tours';
  static const String getParticipantUrl =
      '$apiBase/forms.php?action=get_participant';
  static const String getToursUrl = '$apiBase/forms.php?action=get_tours';
  static const String getParticipantsUrl =
      '$apiBase/forms.php?action=get_participants';

  // Notification endpoints
  static const String registerFcmUrl =
      '$apiBase/notifications.php?action=register_token';
  static const String unregisterFcmUrl =
      '$apiBase/notifications.php?action=unregister_token';

  // ─── STORAGE KEYS ─────────────────────────────────────────
  static const String tokenKey = 'api_token';
  static const String userKey = 'user_data';
  static const String siteDataCacheKey = 'site_data_cache';
  static const String participantCacheKey = 'participant_cache';
  static const String toursCacheKey = 'tours_cache';
  static const String darkModeKey = 'dark_mode';
  static const String etagKey = 'site_data_etag';

  // ─── APP INFO ─────────────────────────────────────────────
  static const String appName = "Audley Achievers' Incentive";
  static const String appVersion = '1.0.0';
  static const Duration cacheMaxAge = Duration(minutes: 30);
  static const Duration tokenRefreshBuffer = Duration(days: 2);

  // ─── VALIDATION ───────────────────────────────────────────
  static const int passwordMinLength = 8;
  static const int otpLength = 6;
}
