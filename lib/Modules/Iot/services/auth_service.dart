import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../models/auth_user.dart';
import '../models/customer_access.dart';
import 'customer_access_service.dart';
import 'session_storage.dart';

class AuthSession {
  const AuthSession({required this.token, required this.user, this.access});

  final String token;
  final AuthUser user;
  final CustomerAccess? access;
}

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  static const Duration _requestTimeout = Duration(seconds: 10);
  static const String _storageKey = 'quik_iot_auth_session';
  static final SessionStorage _storage = createSessionStorage();
  static String? _currentToken;
  static VoidCallback? onAuthFailure;

  static String? get currentToken => _currentToken;

  static Map<String, String> get authorizedJsonHeaders => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (_currentToken != null) 'Authorization': 'Bearer $_currentToken',
  };

  static Map<String, String> get authorizedHeaders => {
    'Accept': 'application/json',
    if (_currentToken != null) 'Authorization': 'Bearer $_currentToken',
  };

  static void clearSession() {
    _currentToken = null;
    _storage.remove(_storageKey);
  }

  static void handleAuthFailure() {
    clearSession();
    onAuthFailure?.call();
  }

  static Future<AuthSession?> restoreSession() async {
    final storedValue = _storage.read(_storageKey);
    if (storedValue == null || storedValue.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(storedValue);
      if (decoded is! Map) {
        clearSession();
        return null;
      }

      final token = decoded['token']?.toString();
      final userJson = decoded['user'];
      if (token == null || userJson is! Map || _isTokenExpired(token)) {
        clearSession();
        return null;
      }

      final user = AuthUser.fromJson(Map<String, dynamic>.from(userJson));
      final access = CustomerAccessService.accessFromBackend(
        email: user.email,
        accessJson: decoded['access'] is Map
            ? Map<String, dynamic>.from(decoded['access'] as Map)
            : null,
      );

      _currentToken = token;
      return AuthSession(token: token, user: user, access: access);
    } catch (_) {
      clearSession();
      return null;
    }
  }

  static Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/api/auth/login'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(_requestTimeout);

      final decodedBody = jsonDecode(response.body);
      if (decodedBody is! Map) {
        throw const FormatException('Expected a JSON object.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthServiceException(
          (decodedBody['error'] ?? decodedBody['message'] ?? 'Login failed.')
              .toString(),
        );
      }

      final token = decodedBody['token'];
      final user = decodedBody['user'];
      if (token is! String || user is! Map) {
        throw const FormatException('Login response was incomplete.');
      }

      final authUser = AuthUser.fromJson(Map<String, dynamic>.from(user));
      final access = CustomerAccessService.accessFromBackend(
        email: authUser.email,
        accessJson: decodedBody['access'] is Map
            ? Map<String, dynamic>.from(decodedBody['access'] as Map)
            : null,
      );

      _currentToken = token;
      debugPrint('[auth] login response access: ${decodedBody['access']}');

      final session = AuthSession(token: token, user: authUser, access: access);
      _storeSession(session);
      return session;
    } on AuthServiceException {
      rethrow;
    } on FormatException {
      throw const AuthServiceException('Login response was not valid JSON.');
    } on http.ClientException catch (error) {
      throw AuthServiceException('Unable to reach login API: ${error.message}');
    }
  }

  static void _storeSession(AuthSession session) {
    _storage.write(
      _storageKey,
      jsonEncode({
        'token': session.token,
        'user': session.user.toJson(),
        'role': session.user.role,
        'access': session.access == null
            ? null
            : CustomerAccessService.accessToBackendJson(session.access!),
      }),
    );
  }

  static bool _isTokenExpired(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return true;
    }

    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) {
        return true;
      }

      final exp = payload['exp'];
      if (exp is! num) {
        return true;
      }

      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp <= nowSeconds;
    } catch (_) {
      return true;
    }
  }
}
