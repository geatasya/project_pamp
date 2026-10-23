abstract class AuthRepository {
  Stream<bool> get authChanges;
  bool get isLoggedIn;
  String? get email;
  Future<void> login(String email, String password);
  Future<void> register(String email, String password);
  Future<void> logout();
}

class Login {
  final AuthRepository repo;
  Login(this.repo);
  Future<void> call(String email, String password) => repo.login(email, password);
}

class Register {
  final AuthRepository repo;
  Register(this.repo);
  Future<void> call(String email, String password) => repo.register(email, password);
}

class Logout {
  final AuthRepository repo;
  Logout(this.repo);
  Future<void> call() => repo.logout();
}
