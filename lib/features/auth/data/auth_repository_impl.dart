import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _c;
  AuthRepositoryImpl(this._c);

  @override
  Stream<bool> get authChanges =>
      _c.auth.onAuthStateChange.map((s) => s.session != null);

  @override
  bool get isLoggedIn => _c.auth.currentSession != null;

  @override
  String? get email => _c.auth.currentUser?.email;

  @override
  Future<void> login(String email, String password) async {
    try {
      await _c.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<void> register(String email, String password) async {
    try {
      await _c.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<void> logout() => _c.auth.signOut();
}
