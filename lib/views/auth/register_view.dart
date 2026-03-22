import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../utils/constants.dart';
import '../../viewmodels/auth_viewmodel.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});
  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirmPass = TextEditingController();
  final _otp = TextEditingController();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();

  bool _otpStage = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _confirmPass.dispose();
    _otp.dispose();
    _name.dispose();
    _age.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Constants.prioLow.withOpacity(0.9) : null,
      ),
    );
  }

  Future<void> _begin() async {
    final auth = context.read<AuthViewModel>();
    auth.clearError();

    final age = int.tryParse(_age.text.trim());
    final weight = double.tryParse(_weight.text.trim());

    if (_name.text.trim().isEmpty) {
      _snack('Please enter your full name.');
      return;
    }
    if (age == null || age < 5 || age > 120) {
      _snack('Please enter a valid age (5-120).');
      return;
    }
    if (weight == null || weight < 10 || weight > 500) {
      _snack('Please enter a valid weight (kg).');
      return;
    }
    if (_pass.text != _confirmPass.text) {
      _snack('Passwords do not match.');
      return;
    }

    final ok = await auth.beginRegistration(
      email: _email.text,
      password: _pass.text,
      confirmPassword: _confirmPass.text,
    );

    if (!mounted) return;
    if (!ok) {
      _snack(auth.error ?? 'Registration failed');
      return;
    }

    setState(() => _otpStage = true);
    _snack(
      'OTP sent to ${_email.text.trim()}. Check your inbox!',
      success: true,
    );
  }

  Future<void> _confirm() async {
    final auth = context.read<AuthViewModel>();
    final age = int.tryParse(_age.text.trim());
    final weight = double.tryParse(_weight.text.trim());
    auth.clearError();

    final ok = await auth.confirmRegistrationOtpAndCreateUser(
      email: _email.text,
      password: _pass.text,
      otpInput: _otp.text,
      age: age,
      weight: weight,
    );

    if (!mounted) return;
    if (ok) {
      _snack('Account created! You can log in now.', success: true);
      Navigator.pop(context);
    } else {
      _snack(auth.error ?? 'OTP verification failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withOpacity(0.15),
                          cs.secondary.withOpacity(0.10),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.primary.withOpacity(0.25)),
                    ),
                    child: Column(children: [
                      Icon(
                        _otpStage
                            ? Icons.mark_email_read_outlined
                            : Icons.person_add_outlined,
                        size: 40,
                        color: cs.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _otpStage ? 'Verify Your Email' : 'Join SkyFit Pro',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        _otpStage
                            ? 'Enter the 6-digit code sent to\n${_email.text.trim()}'
                            : 'Fill in your details to get started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ]),
                  )
                      .animate()
                      .fadeIn()
                      .slideY(begin: -0.08, end: 0, duration: 350.ms),

                  const SizedBox(height: 24),

                  // ── Step 1 Fields ──────────────────────────────────────
                  AnimatedOpacity(
                    opacity: _otpStage ? 0.45 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Column(children: [
                      TextField(
                        controller: _name,
                        enabled: !auth.isBusy && !_otpStage,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _email,
                        enabled: !auth.isBusy && !_otpStage,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _age,
                            enabled: !auth.isBusy && !_otpStage,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              prefixIcon: Icon(Icons.cake_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _weight,
                            enabled: !auth.isBusy && !_otpStage,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              prefixIcon: Icon(Icons.monitor_weight_outlined),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pass,
                        enabled: !auth.isBusy && !_otpStage,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password (min 8 chars)',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPass,
                        enabled: !auth.isBusy && !_otpStage,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: const Icon(Icons.lock_person_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                      ),
                    ]),
                  ),

                  // ── Step 2: OTP Field ──────────────────────────────────
                  if (_otpStage) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _otp,
                      enabled: !auth.isBusy,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 12,
                      ),
                      decoration: InputDecoration(
                        labelText: '6-Digit OTP',
                        counterText: '',
                        prefixIcon: const Icon(Icons.key_outlined),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.secondary, width: 2),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .scale(begin: const Offset(0.95, 0.95)),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: auth.isBusy
                            ? null
                            : () {
                                setState(() => _otpStage = false);
                                _otp.clear();
                              },
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text('Change details'),
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  // ── Primary Button ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          auth.isBusy ? null : (_otpStage ? _confirm : _begin),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _otpStage ? cs.secondary : cs.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(
                        _otpStage
                            ? Icons.verified_user_outlined
                            : Icons.send_outlined,
                        size: 20,
                      ),
                      label: auth.isBusy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_otpStage
                              ? 'Verify & Create Account'
                              : 'Send OTP to Email'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Info note ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.secondary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.secondary.withOpacity(0.25)),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline, size: 16, color: cs.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'OTP expires in 10 minutes. '
                          'Age & weight help personalize your activity suggestions.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ),
                    ]),
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
