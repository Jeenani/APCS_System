import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && ApiClient.isAuthenticated;

  Future<void> tryAutoLogin() async {
    await ApiClient.loadTokens();
    if (!ApiClient.isAuthenticated) return;

    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      _user = UserModel.fromJson(jsonDecode(userData));
      notifyListeners();
    }
  }

  Future<bool> login(String login, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.post('/auth/login', {
        'login': login,
        'password': password,
      });

      await ApiClient.saveTokens(
        response['access_token'],
        response['refresh_token'],
      );

      _user = UserModel.fromJson(response['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(response['user']));

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Ошибка подключения к серверу: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String login, String password, String fullName, int roleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiClient.post('/auth/register', {
        'login': login,
        'password': password,
        'full_name': fullName,
        'role_id': roleId,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Ошибка подключения к серверу';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiClient.clearTokens();
    _user = null;
    notifyListeners();
  }
}
