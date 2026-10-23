import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;
  final Login _login;
  final Register _register;
  final Logout _logout;
  StreamSubscription<bool>? _sub;

  bool isLoading = false;
  bool isLoggedIn = false;
  String? error;
  String? info;

  AuthProvider(this._repo, this._login, this._register, this._logout) {
    isLoggedIn = _repo.isLoggedIn;
    _sub = _repo.authChanges.listen((v) {
      isLoggedIn = v;
      notifyListeners();
    });
  }

  String? get email => _repo.email;

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> login(String email, String password) async {
    isLoading = true; error = null; info = null;
    notifyListeners();
    try {
      await _login(email, password);
    } catch (e) {
      error = _msg(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    isLoading = true; error = null; info = null;
    notifyListeners();
    try {
      await _register(email, password);
      if (!_repo.isLoggedIn) {
        info = 'Akun dibuat! Cek email untuk konfirmasi, lalu login.';
      }
    } catch (e) {
      error = _msg(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> logout() => _logout();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
