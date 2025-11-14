import '../../../features/auth/repositories/i_auth_repository.dart';

final class FakeAuthRepository implements IAuthRepository {
  String? _userId;

  @override
  bool get isSignedIn => _userId != null;

  @override
  String? get userId => _userId;

  @override
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _userId = email;
  }

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _userId = email;
  }

  @override
  Future<void> signOut() async {
    _userId = null;
  }
}
