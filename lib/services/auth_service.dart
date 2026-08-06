import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _lastLoginAtKey = 'auth.last_login_at';
  static const String _displayNameKey = 'auth.display_name';

  Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastLoginAtKey);
    if (raw == null || raw.isEmpty) {
      return false;
    }

    final lastLoginAt = DateTime.tryParse(raw);
    if (lastLoginAt == null) {
      return false;
    }

    final expiresAt = _addMonths(lastLoginAt, 3);
    return DateTime.now().isBefore(expiresAt);
  }

  Future<bool> signIn({
    required String username,
    required String password,
  }) async {
    final authorized = await _authorize(username: username, password: password);
    if (!authorized) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final safeUsername = username.trim().isEmpty ? 'Invitad@' : username.trim();
    await prefs.setString(_lastLoginAtKey, DateTime.now().toIso8601String());
    await prefs.setString(_displayNameKey, safeUsername);
    return true;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLoginAtKey);
    await prefs.remove(_displayNameKey);
  }

  Future<String?> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_displayNameKey);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value;
  }

  Future<bool> _authorize({
    required String username,
    required String password,
  }) async {
    // Placeholder for a real authorization service integration.
    // Future implementation idea:
    // 1. Call backend endpoint.
    // 2. Validate token.
    // 3. Persist secure session artifacts.
    return true;
  }

  DateTime _addMonths(DateTime date, int months) {
    final totalMonths = date.month + months;
    final year = date.year + ((totalMonths - 1) ~/ 12);
    final month = ((totalMonths - 1) % 12) + 1;

    final nextMonthStart = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    final lastDayOfTargetMonth = nextMonthStart.subtract(const Duration(days: 1)).day;

    final day = date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;

    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }
}
