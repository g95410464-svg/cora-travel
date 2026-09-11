import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _auth = AuthService();
  StreamSubscription<String>? _authErrorSub;
  String? _verificationId;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _authErrorSub = _auth.authErrors.listen((message) {
      if (mounted) setState(() => _error = message);
    });
  }

  @override
  void dispose() {
    _authErrorSub?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _auth.signInWithGoogle();
    } on AuthServiceException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo abrir Google. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() async {
    final phone = _phone.text.trim();
    if (!phone.startsWith('+') || phone.length < 10) {
      setState(() => _error =
          'Escribe tu número con código de país, por ejemplo +50370000000.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _auth.sendCode(
        phone: phone,
        onCodeSent: (id) {
          if (mounted) {
            setState(() {
              _verificationId = id;
              _busy = false;
            });
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _error = _message(e);
              _busy = false;
            });
          }
        },
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = _message(e);
          _busy = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo enviar el código. Intenta de nuevo.';
          _busy = false;
        });
      }
    }
  }

  Future<void> _verify() async {
    if (_verificationId == null || _code.text.trim().length < 6) {
      setState(
          () => _error = 'Escribe el código de 6 dígitos recibido por SMS.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _auth.verifyCode(_verificationId!, _code.text.trim());
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo verificar el código. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(FirebaseAuthException e) => switch (e.code) {
        'invalid-phone-number' => 'El número no es válido.',
        'too-many-requests' => 'Demasiados intentos. Espera un momento.',
        'invalid-verification-code' => 'El código no es correcto.',
        'network-request-failed' => 'Revisa tu conexión a internet.',
        'automatic-verification-failed' =>
          'No se pudo verificar automáticamente. Solicita el código por SMS.',
        'cancelled' => 'Inicio de sesión cancelado.',
        _ => 'No se pudo iniciar sesión. Intenta de nuevo.',
      };

  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ListView(
                      padding: const EdgeInsets.all(28),
                      children: [
                        const SizedBox(height: 40),
                        const CircleAvatar(
                            radius: 34,
                            backgroundColor: Color(0xFF007F79),
                            child: Icon(Icons.auto_awesome,
                                color: Colors.white, size: 32)),
                        const SizedBox(height: 24),
                        const Text('Bienvenido a CORA',
                            style: TextStyle(
                                fontSize: 32, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text(
                            'Inicia sesión para guardar tu perfil y tus preferencias de viaje.',
                            style: TextStyle(
                                fontSize: 16, color: Color(0xFF53665F))),
                        const SizedBox(height: 28),
                        FilledButton.icon(
                            onPressed: _busy ? null : _google,
                            icon: const Icon(Icons.login),
                            label: const Text('Continuar con Google')),
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 22),
                            child: Row(children: [
                              Expanded(child: Divider()),
                              Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('o')),
                              Expanded(child: Divider())
                            ])),
                        TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                                labelText: 'Número de teléfono',
                                hintText: '+503 7000 0000',
                                prefixIcon: Icon(Icons.phone_outlined))),
                        const SizedBox(height: 12),
                        if (_verificationId == null)
                          OutlinedButton(
                              onPressed: _busy ? null : _sendCode,
                              child: const Text('Enviar código por SMS')),
                        if (_verificationId != null) ...[
                          TextField(
                              controller: _code,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: const InputDecoration(
                                  labelText: 'Código de verificación',
                                  prefixIcon: Icon(Icons.sms_outlined))),
                          FilledButton(
                              onPressed: _busy ? null : _verify,
                              child: const Text('Verificar y continuar')),
                        ],
                        if (_busy)
                          const Padding(
                              padding: EdgeInsets.only(top: 18),
                              child: LinearProgressIndicator()),
                        if (_error != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 18),
                              child: Text(_error!,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error))),
                        const SizedBox(height: 22),
                        const Text(
                            'El acceso con Google se completa de forma segura en el navegador. El SMS sigue usando Firebase.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF53665F))),
                      ])))));
}
