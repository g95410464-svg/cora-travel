import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _google = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) {
      throw FirebaseAuthException(code: 'cancelled');
    }

    final tokens = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: tokens.accessToken,
      idToken: tokens.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> sendCode({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        try {
          await _auth.signInWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          onError(e);
        } catch (_) {
          onError(FirebaseAuthException(code: 'automatic-verification-failed'));
        }
      },
      verificationFailed: onError,
      codeSent: (id, _) => onCodeSent(id),
      codeAutoRetrievalTimeout: onCodeSent,
    );
  }

  Future<UserCredential> verifyCode(String verificationId, String code) {
    return _auth.signInWithCredential(
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      ),
    );
  }

  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }
}
