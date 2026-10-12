import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  final ApiService _apiService = ApiService();
  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _checkUser();
  }

  Future<void> _checkUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        try {
          _user = await _apiService.getCurrentUser();
        } catch (e) {
          // Token invalid or expired, silently clear it
          if (!e.toString().contains('401') && !e.toString().contains('403')) {
            debugPrint('Unexpected error validating token: $e');
          }
          await prefs.remove('auth_token');
          await prefs.remove('exness_user');
        }
      }
    } catch (e) {
      debugPrint('Error checking user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      final token = response['access_token'] as String;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      // Fetch user details
      _user = await _apiService.getCurrentUser();
      await prefs.setString('exness_user', _user!.toJson().toString());

      notifyListeners();
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  Future<void> loginWithOkta() async {
    try {
      final AuthorizationTokenResponse? result = await _appAuth
          .authorizeAndExchangeCode(
            AuthorizationTokenRequest(
              ApiConfig.oktaClientId,
              ApiConfig.oktaRedirectUrl,
              issuer: ApiConfig.oktaIssuer,
              scopes: ['openid', 'profile', 'email', 'offline_access'],
              promptValues: ['login'],
            ),
          );

      if (result != null && result.accessToken != null) {
        // Exchange Okta token for backend token
        final response = await _apiService.oktaLogin(result.accessToken!);
        final token = response['access_token'] as String;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        // Fetch user details
        _user = await _apiService.getCurrentUser();
        await prefs.setString('exness_user', _user!.toJson().toString());

        notifyListeners();
      } else {
        throw Exception('Login cancelled or failed');
      }
    } catch (e) {
      debugPrint('Okta Login error: $e');
      rethrow;
    }
  }

  Future<void> register(String email, String password, String fullName) async {
    try {
      final response = await _apiService.register(email, password, fullName);
      final token = response['access_token'] as String;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      // Fetch user details
      _user = await _apiService.getCurrentUser();
      await prefs.setString('exness_user', _user!.toJson().toString());

      notifyListeners();
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('exness_user');
    notifyListeners();
  }
}
