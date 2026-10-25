import 'package:firebase_auth/firebase_auth.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}

class AuthService {
  AuthService();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signIn(String email, String password) => _guard(() async {
        await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      });

  Future<void> register(String name, String email, String password) => _guard(() async {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        await cred.user?.updateDisplayName(name.trim());
      });

  Future<void> signInAsGuest() => _guard(() async {
        await _auth.signInAnonymously();
      });

  Future<void> resetPassword(String email) => _guard(() async {
        await _auth.sendPasswordResetEmail(email: email.trim());
      });

  Future<void> signOut() => _auth.signOut();

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code));
    } catch (_) {
      throw const AuthFailure('حدث خطأ غير متوقع، حاول مرة أخرى');
    }
  }

  String _message(String code) {
    switch (code) {
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'البريد أو كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'هذا البريد مسجّل مسبقاً';
      case 'weak-password':
        return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
      case 'network-request-failed':
        return 'لا يوجد اتصال بالإنترنت';
      case 'too-many-requests':
        return 'محاولات كثيرة، انتظر قليلاً ثم حاول';
      case 'user-disabled':
        return 'هذا الحساب معطّل';
      case 'operation-not-allowed':
        return 'طريقة الدخول غير مفعّلة في Firebase';
      default:
        return 'تعذّر تنفيذ العملية ($code)';
    }
  }
}
