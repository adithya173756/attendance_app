import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthService {
  static const String _boxName = 'authBox';

  static const String _usernameKey = 'username';
  static const String _passwordHashKey = 'passwordHash';
  static const String _loggedInKey = 'loggedIn';

  static late Box _box;

  // ============================================================
  // INITIALIZE
  // ============================================================

  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);

    // Keep the saved session across app restarts. Explicit logout still
    // clears only the session flag, leaving the account and local academic
    // data intact.
  }

  // ============================================================
  // HASH PASSWORD
  // ============================================================

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);

    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  // ============================================================
  // CHECK ACCOUNT
  // ============================================================

  static bool hasAccount() {
    return _box.get(_usernameKey) != null && _box.get(_passwordHashKey) != null;
  }

  // ============================================================
  // CREATE ACCOUNT
  // ============================================================

  static Future<void> createAccount({
    required String username,
    required String password,
  }) async {
    await _box.put(_usernameKey, username.trim().toLowerCase());

    await _box.put(_passwordHashKey, _hashPassword(password));

    await _box.put(_loggedInKey, false);
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<bool> login({
    required String username,
    required String password,
  }) async {
    final savedUsername = _box.get(_usernameKey);

    final savedPasswordHash = _box.get(_passwordHashKey);

    if (savedUsername == null || savedPasswordHash == null) {
      return false;
    }

    final enteredUsername = username.trim().toLowerCase();

    final enteredPasswordHash = _hashPassword(password);

    if (enteredUsername != savedUsername) {
      return false;
    }

    if (enteredPasswordHash != savedPasswordHash) {
      return false;
    }

    await _box.put(_loggedInKey, true);

    return true;
  }

  // ============================================================
  // LOGGED IN
  // ============================================================

  static bool isLoggedIn() {
    return _box.get(_loggedInKey, defaultValue: false) == true;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> logout() async {
    await _box.put(_loggedInKey, false);
  }

  // ============================================================
  // CLEAR ACCOUNT
  // ============================================================

  static Future<void> clearAccount() async {
    await _box.clear();
  }

  // ============================================================
  // USERNAME
  // ============================================================

  static String getUsername() {
    return _box.get(_usernameKey, defaultValue: "") ?? "";
  }
}
