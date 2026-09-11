import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';

class AuthServiceException implements Exception {
  final String code;
  final String message;
  const AuthServiceException(this.code, this.message);

  @override
  String toString() => message;
}

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  static const _tokenKey = 'cora.oauth.session_token';
  static const _userKey = 'cora.oauth.user';

  final FirebaseAuth _firebase = FirebaseAuth.instance;
  final AppLinks _appLinks = AppLinks();
  final StreamController<bool> _authChanges = StreamController<bool>.broadcast();
  final StreamController<String> _authErrors = StreamController<String>.broadcast();
  final Set<String> _handledLinks = <String>{};

  StreamSubscription<User?>? _firebaseSub;
  StreamSubscription<Uri>? _linkSub;
  bool _initialized = false;
  String? _oauthToken;
  Map<String, dynamic>? _oauthUser;

  User? get currentUser => _firebase.currentUser;
  Map<String, dynamic>? get oauthUser => _oauthUser;
  bool get isSignedIn => _firebase.currentUser != null || (_oauthToken?.isNotEmpty ?? false);
  Stream<bool> get authStateChanges => _authChanges.stream;
  Stream<String> get authErrors => _authErrors.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    _oauthToken = prefs.getString(_tokenKey);
    final savedUser = prefs.getString(_userKey);
    if (savedUser != null && savedUser.isNotEmpty) {
      try {
        _oauthUser = jsonDecode(savedUser) as Map<String, dynamic>;
      } catch (_) {
        await prefs.remove(_userKey);
      }
    }

    _firebaseSub = _firebase.authStateChanges().listen((_) => _emitAuthState());

    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      unawaited(_handleAuthLink(initialLink));
    }
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handleAuthLink(uri)),
      onError: (_) => _authErrors.add('No se pudo completar el regreso desde Google.'),
    );

    _emitAuthState();
  }

  Uri _endpoint(String path) => Uri.parse(AppConfig.apiBaseUrl).resolve(path);

  void _emitAuthState() => _authChanges.add(isSignedIn);

  Future<void> signInWithGoogle() async {
    final endpoint = _endpoint('/auth/google/redirect');
    final launched = await launchUrl(endpoint, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw const AuthServiceException(
        'google-browser-failed',
        'No se pudo abrir Google para iniciar sesión.',
      );
    }
  }

  Future<void> _handleAuthLink(Uri uri) async {
    if (uri.scheme != 'cora' || uri.host != 'auth' || uri.path != '/callback') return;
    final raw = uri.toString();
    if (!_handledLinks.add(raw)) return;

    final error = uri.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      _authErrors.add(_googleCallbackMessage(error));
      return;
    }

    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      _authErrors.add('Google regresó sin un código de acceso válido.');
      return;
    }

    try {
      final response = await http
          .post(
            _endpoint('/auth/mobile/exchange'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw const AuthServiceException(
          'oauth-exchange-failed',
          'No se pudo completar el inicio de sesión con Google.',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['token'];
      final user = body['user'];
      if (token is! String || token.isEmpty || user is! Map<String, dynamic>) {
        throw const AuthServiceException(
          'oauth-response-invalid',
          'El servidor devolvió una sesión de Google inválida.',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user));
      _oauthToken = token;
      _oauthUser = user;
      _emitAuthState();
    } on TimeoutException {
      _authErrors.add('El servidor tardó demasiado en completar el inicio con Google.');
    } on AuthServiceException catch (e) {
      _authErrors.add(e.message);
    } catch (_) {
      _authErrors.add('No se pudo completar el inicio de sesión con Google.');
    }
  }

  String _googleCallbackMessage(String code) => switch (code) {
        'google_denied' => 'Inicio de sesión con Google cancelado.',
        'invalid_oauth_state' => 'La sesión de Google venció. Intenta de nuevo.',
        'google_unavailable' => 'Google no está disponible en este momento.',
        _ => 'No se pudo completar el inicio de sesión con Google.',
      };

  Future<void> sendCode({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException error) onError,
  }) async {
    await _firebase.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        try {
          await _firebase.signInWithCredential(credential);
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
    return _firebase.signInWithCredential(
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      ),
    );
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _oauthToken = null;
    _oauthUser = null;
    if (_firebase.currentUser != null) await _firebase.signOut();
    _emitAuthState();
  }

  Future<void> dispose() async {
    await _firebaseSub?.cancel();
    await _linkSub?.cancel();
    await _authChanges.close();
    await _authErrors.close();
  }
}
