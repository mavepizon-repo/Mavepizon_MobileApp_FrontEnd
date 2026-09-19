import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  StorageHelper._();

  static SharedPreferences? _prefs;

  /// Preloads SharedPreferences before the UI builds so startup reads (theme,
  /// auth) are reliable and instant.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Cached instance (available after [init] has completed).
  static SharedPreferences get prefs {
    final p = _prefs;
    if (p == null) {
      throw StateError('StorageHelper.init() must be called before prefs access');
    }
    return p;
  }

  static const String _keyToken = 'auth_token';
  static const String _keyRole = 'user_role';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyStaffCategory = 'staff_category';
  static const String _keyUserProfile = 'user_profile';
  static const String _keyThemeMode = 'theme_mode';

  static String _themeKey(String userId) => 'theme_mode_$userId';

  static Future<void> saveLoginData({
    required String token,
    required String role,
    required String userId,
    required String userName,
    required String userEmail,
    String staffCategory = '',
    String userProfile = '',
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyToken, token);
    await p.setString(_keyRole, role);
    await p.setString(_keyUserId, userId);
    await p.setString(_keyUserName, userName);
    await p.setString(_keyUserEmail, userEmail);
    await p.setString(_keyStaffCategory, staffCategory);
    await p.setString(_keyUserProfile, userProfile);
  }

  static Future<String?> getToken() async {
    return (await SharedPreferences.getInstance()).getString(_keyToken);
  }

  static Future<String?> getRole() async {
    return (await SharedPreferences.getInstance()).getString(_keyRole);
  }

  static Future<String?> getUserId() async {
    return (await SharedPreferences.getInstance()).getString(_keyUserId);
  }

  static Future<String?> getUserName() async {
    return (await SharedPreferences.getInstance()).getString(_keyUserName);
  }

  static Future<String?> getUserEmail() async {
    return (await SharedPreferences.getInstance()).getString(_keyUserEmail);
  }

  static Future<String?> getStaffCategory() async {
    return (await SharedPreferences.getInstance()).getString(_keyStaffCategory);
  }

  static Future<String?> getUserProfile() async {
    return (await SharedPreferences.getInstance()).getString(_keyUserProfile);
  }

  static Future<String?> getStaffId() => getUserId();
  static Future<String?> getCollegeStaffId() => getUserId();

  static String _shiftStartKey(String staffId) => 'shift_start_$staffId';
  static String _shiftEndKey(String staffId) => 'shift_end_$staffId';

  /// Persists the per-staff shift start/end times locally so the staff
  /// attendance screen can show the correct custom check-in window (the
  /// backend does not return these fields in the login/profile responses).
  static Future<void> saveStaffShiftTime(
    String staffId, {
    required String shiftStartTime,
    required String shiftEndTime,
  }) async {
    final p = await SharedPreferences.getInstance();
    if (shiftStartTime.isNotEmpty) {
      await p.setString(_shiftStartKey(staffId), shiftStartTime);
    }
    if (shiftEndTime.isNotEmpty) {
      await p.setString(_shiftEndKey(staffId), shiftEndTime);
    }
  }

  static Future<String?> getStaffShiftStartTime(String staffId) async {
    return (await SharedPreferences.getInstance())
        .getString(_shiftStartKey(staffId));
  }

  static Future<String?> getStaffShiftEndTime(String staffId) async {
    return (await SharedPreferences.getInstance()).getString(_shiftEndKey(staffId));
  }

  static Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyToken);
    await p.remove(_keyRole);
    await p.remove(_keyUserId);
    await p.remove(_keyUserName);
    await p.remove(_keyUserEmail);
    await p.remove(_keyStaffCategory);
    await p.remove(_keyUserProfile);
    // Keep each user's theme preference so it is restored on their next login.
  }

  /// Saves the theme. When [userId] is provided it is stored per-user so each
  /// person's choice only applies to themselves; the legacy global key is also
  /// kept in sync for backward compatibility (defaults to 'light').
  static Future<void> saveThemeMode(String mode, {String? userId}) async {
    final p = await SharedPreferences.getInstance();
    if (userId != null && userId.isNotEmpty) {
      await p.setString(_themeKey(userId), mode);
    }
    await p.setString(_keyThemeMode, mode);
  }

  static Future<String> getThemeMode({String? userId}) async {
    final p = await SharedPreferences.getInstance();
    if (userId != null && userId.isNotEmpty) {
      final perUser = p.getString(_themeKey(userId));
      if (perUser != null) return perUser;
    }
    return p.getString(_keyThemeMode) ?? 'light';
  }

  /// Synchronous variants used only after [init] has completed (e.g. theme
  /// loading at app startup before the first frame).
  static String? getUserIdSync() => prefs.getString(_keyUserId);

  static String getThemeModeSync({String? userId}) {
    final p = prefs;
    if (userId != null && userId.isNotEmpty) {
      final perUser = p.getString(_themeKey(userId));
      if (perUser != null) return perUser;
    }
    return p.getString(_keyThemeMode) ?? 'light';
  }
}
