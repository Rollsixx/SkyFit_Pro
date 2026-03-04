import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/constants.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'register_view.dart';
import 'todo_list_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _login() async {
    final auth = context.read<AuthViewModel>();
    auth.clearError();

    final ok = await auth.loginWithPassword(
      email: _email.text,
      password: _password.text,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => TodoListView()),
      );
    } else {
      _showSnack(auth.error ?? 'Login failed');
    }
  }

  Future<void> _bioUnlock() async {
    final auth = context.read<AuthViewModel>();
    auth.clearError();
    final ok = await auth.unlockWithBiometrics();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => TodoListView()),
      );
    } else {
      _showSnack(auth.error ?? 'Biometric unlock failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Constants.dsBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    Constants.dsBlack.withOpacity(0.95),
                    Constants.dsCrimson.withOpacity(0.22),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Constants.dsTeal.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    spreadRadius: 2,
                    color: Colors.black.withOpacity(0.35),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'CipherTask',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Demon Slayer Mode • Secure To-Do',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.alternate_email, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: auth.isBusy ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.dsCrimson,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: auth.isBusy
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: auth.isBusy ? null : _bioUnlock,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Constants.dsTeal.withOpacity(0.7)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Unlock with Fingerprint'),
                  ),

                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: auth.isBusy
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterView()),
                            );
                          },
                    child: const Text('Create account (OTP simulation)'),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Session auto-lock: ${Constants.inactivityTimeoutSeconds}s',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}