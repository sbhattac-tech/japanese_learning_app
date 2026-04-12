import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _usersKey = 'auth_users';
  static const _currentUserKey = 'auth_current_user';

  Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  Future<void> signUp({
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _loadUsers();
    if (users.containsKey(username)) {
      throw Exception('That username is already taken.');
    }
    users[username] = password;
    await prefs.setString(_usersKey, jsonEncode(users));
    await prefs.setString(_currentUserKey, username);
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _loadUsers();
    if (users[username] != password) {
      throw Exception('Incorrect username or password.');
    }
    await prefs.setString(_currentUserKey, username);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  Future<Map<String, String>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }
}
