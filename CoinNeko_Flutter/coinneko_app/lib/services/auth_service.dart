// frontend/lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  static const String _baseUrl = 'http://localhost:8000/api';
  static const _storage = FlutterSecureStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  // ── Token 管理 ──
  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshKey);
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  // ── 自動刷新 token ──
  Future<String?> getValidAccessToken() async {
    final token = await getAccessToken();
    if (token == null) return null;

    // 嘗試用 refresh token 取得新 access token
    final refresh = await getRefreshToken();
    if (refresh == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        await _storage.write(key: _accessKey, value: data['access']);
        if (data['refresh'] != null) {
          await _storage.write(key: _refreshKey, value: data['refresh']);
        }
        return data['access'];
      }
    } catch (_) {}
    return token; // fallback 舊 token
  }

  // ── 啟動時自動還原登入狀態 ──
  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _user = UserModel.fromJson(
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
      } else {
        await clearTokens();
      }
    } catch (_) {
      await clearTokens();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── 註冊 ──
  Future<String?> register({
    required String username,
    required String password,
    required String password2,
    String email = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'password2': password2,
          'email': email,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        await saveTokens(data['access'], data['refresh']);
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        notifyListeners();
        return null; // 成功
      } else {
        return _extractError(data);
      }
    } catch (e) {
      return '網路連線錯誤：$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── 登入 ──
  Future<String?> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        await saveTokens(data['access'], data['refresh']);
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        notifyListeners();
        return null;
      } else {
        return data['error'] as String? ?? '登入失敗';
      }
    } catch (e) {
      return '網路連線錯誤：$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── 登出 ──
  Future<void> logout() async {
    final refresh = await getRefreshToken();
    final access = await getAccessToken();

    if (refresh != null && access != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/auth/logout/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $access',
          },
          body: jsonEncode({'refresh': refresh}),
        );
      } catch (_) {}
    }

    await clearTokens();
    _user = null;
    notifyListeners();
  }

  void updateUser(UserModel updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  String _extractError(Map<String, dynamic> data) {
    if (data.containsKey('error')) return data['error'].toString();
    // DRF validation error format
    final errors = <String>[];
    data.forEach((key, value) {
      if (value is List) {
        errors.add('$key: ${value.join(', ')}');
      } else {
        errors.add('$key: $value');
      }
    });
    return errors.join('\n');
  }
}