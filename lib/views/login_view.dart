import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../utils/constants.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import 'register_view.dart';
import 'home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _obscure = true;

  // ── Tracks whether we already auto-prompted biometrics this session ─────────
  bool _biometricAutoPrompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthViewModel>();

      // 1. Check hardware availability
      await auth.checkBiometricsAvailability();

      // 2. If hardware available AND last user had biometrics enabled,
      //    auto-prompt without waiting for button tap
      if (!_biometricAutoPrompted &&
          auth.biometricsAvailable &&
          !auth.biometricLocked) {
        final shouldPrompt = await auth.lastUserHasBiometricsEnabled();
        if (shouldPrompt && mounted) {
          _biometricAutoPrompted = true;
          await _bioUnlock(autoPrompt: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _goHome() => Navigator.of(context)
      .pushReplacement(MaterialPageRoute(builder: (_) => const HomeView()));

  // ── Password login ─────────────────────────────────────────────────────────
  Future<void> _login() async {
    final auth = context.read<AuthViewModel>();
    auth.clearError();
    // Reset bio fail counter when user chooses to use password
    auth.resetBioFailCount();
    final ok = await auth.loginWithPassword(
        email: _email.text, password: _password.text);
    if (!mounted) return;
    if (ok)
      _goHome();
    else
      _snack(auth.error ?? 'Login failed');
  }

  // ── Google login ───────────────────────────────────────────────────────────
  Future<void> _googleLogin() async {
    final auth = context.read<AuthViewModel>();
    auth.clearError();
    final ok = await auth.beginGoogleLogin();
    if (!mounted) return;
    if (ok)
      _showGoogleOtpDialog();
    else if (auth.error != null) _snack(auth.error!);
  }

  void _showGoogleOtpDialog() {
    final auth = context.read<AuthViewModel>();
    final email = auth.pendingGoogleEmail ?? '';
    final cs = Theme.of(context).colorScheme;
    _otpCtrl.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Image.network(
              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
              height: 24,
              width: 24,
              errorBuilder: (_, __, ___) => Icon(Icons.g_mobiledata_rounded,
                  color: cs.secondary, size: 28),
            ),
            const SizedBox(width: 8),
            const Text('Verify Your Email'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('A 6-digit code was sent to:',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              Text(email,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: cs.secondary)),
              const SizedBox(height: 4),
              const Text('Check your inbox (or debug console).',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 12),
                decoration: InputDecoration(
                  counterText: '',
                  labelText: '6-Digit OTP',
                  prefixIcon: const Icon(Icons.key_outlined),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: cs.secondary, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<AuthViewModel>().cancelGoogleOtp();
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: auth.isBusy
                  ? null
                  : () async {
                      await context.read<AuthViewModel>().beginGoogleLogin();
                      if (mounted) _snack('New OTP sent!');
                    },
              child: Text('Resend', style: TextStyle(color: cs.secondary)),
            ),
            FilledButton(
              onPressed: auth.isBusy
                  ? null
                  : () async {
                      final vm = context.read<AuthViewModel>();
                      final ok2 = await vm.confirmGoogleOtp(_otpCtrl.text);
                      if (!mounted) return;
                      if (ok2) {
                        Navigator.pop(ctx);
                        _goHome();
                      } else {
                        _snack(vm.error ?? 'Invalid OTP');
                      }
                    },
              style: FilledButton.styleFrom(backgroundColor: cs.secondary),
              child: auth.isBusy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Verify', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Biometric unlock ───────────────────────────────────────────────────────
  /// [autoPrompt] = true means this was triggered automatically on launch,
  /// not by the user tapping the button. If it fails silently, we don't
  /// lock the user out — they simply see the normal login form.
  Future<void> _bioUnlock({bool autoPrompt = false}) async {
    final auth = context.read<AuthViewModel>();
    auth.clearError();
    final ok = await auth.unlockWithBiometrics();
    if (!mounted) return;
    if (ok) {
      _goHome();
    } else {
      final msg = auth.error ?? 'Biometric failed';
      // Only show snackbar if user intentionally tapped the button
      if (!autoPrompt) _snack(msg);
      // Force a rebuild so the UI reflects the new fail count / lock state
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final themeVm = context.watch<ThemeViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bioOk = auth.biometricsChecked &&
        auth.biometricsAvailable &&
        !auth.biometricLocked;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(children: [
        // ── Background blobs ──────────────────────────────────────────────
        Positioned(
          top: -80,
          right: -60,
          child: _Blob(
              color: cs.primary.withOpacity(isDark ? 0.25 : 0.12), size: 260),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: _Blob(
              color: cs.secondary.withOpacity(isDark ? 0.2 : 0.10), size: 300),
        ),

        // ── Theme toggle ──────────────────────────────────────────────────
        Positioned(
          top: 48,
          right: 16,
          child: IconButton(
            icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: themeVm.toggle,
          ),
        ),

        // ── Main content ──────────────────────────────────────────────────
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo ───────────────────────────────────────────────
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const Icon(Icons.fitness_center_rounded,
                        size: 36, color: Colors.white),
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 16),

                  // ── App name ───────────────────────────────────────────
                  Text('SkyFit Pro',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5))
                      .animate()
                      .fadeIn(delay: 100.ms),
                  Text('Your personal health companion',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium)
                      .animate()
                      .fadeIn(delay: 200.ms),

                  const SizedBox(height: 32),

                  // ── Email ──────────────────────────────────────────────
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                  ).animate().fadeIn(delay: 250.ms),

                  const SizedBox(height: 14),

                  // ── Password ───────────────────────────────────────────
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 22),

                  // ── Sign In ────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: auth.isBusy ? null : _login,
                      icon: const Icon(Icons.login_rounded),
                      label: auth.isBusy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Sign In'),
                    ),
                  ).animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: 12),

                  // ── OR divider ─────────────────────────────────────────
                  Row(children: [
                    Expanded(
                        child: Divider(
                            color: isDark ? Colors.white24 : Colors.black26)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 13)),
                    ),
                    Expanded(
                        child: Divider(
                            color: isDark ? Colors.white24 : Colors.black26)),
                  ]),

                  const SizedBox(height: 12),

                  // ── Google ─────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: auth.isBusy ? null : _googleLogin,
                      icon: Image.network(
                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                        height: 18,
                        width: 18,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.g_mobiledata_rounded, size: 22),
                      ),
                      label: const Text('Continue with Google'),
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 10),

                  // ── Biometrics button ──────────────────────────────────
                  // Shows LOCKED state when bio fails >= 3
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          (auth.isBusy || !bioOk) ? null : () => _bioUnlock(),
                      icon: Icon(
                        auth.biometricLocked
                            ? Icons.lock_rounded
                            : Icons.fingerprint_rounded,
                      ),
                      label: Text(
                        auth.biometricLocked
                            ? 'Biometrics locked — use password'
                            : !auth.biometricsChecked
                                ? 'Checking biometrics...'
                                : !auth.biometricsAvailable
                                    ? 'Fingerprint not available'
                                    : auth.bioFailCount > 0
                                        ? 'Retry Fingerprint '
                                            '(${auth.maxBioFails - auth.bioFailCount} left)'
                                        : 'Unlock with Fingerprint',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: auth.biometricLocked
                            ? Colors.red
                            : isDark
                                ? Colors.white60
                                : Colors.black54,
                        side: BorderSide(
                          color: auth.biometricLocked
                              ? Colors.red.withOpacity(0.5)
                              : isDark
                                  ? Colors.white24
                                  : Colors.black26,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 440.ms),

                  // ── Bio fail warning ───────────────────────────────────
                  if (auth.bioFailCount > 0 && !auth.biometricLocked)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '⚠️  ${auth.bioFailCount}/${auth.maxBioFails} failed attempts',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.orange),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(),

                  if (auth.biometricLocked)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '🔒  Biometrics locked. Use your password to sign in.',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(),

                  const SizedBox(height: 20),

                  // ── Register link ──────────────────────────────────────
                  Center(
                    child: TextButton(
                      onPressed: auth.isBusy
                          ? null
                          : () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const RegisterView())),
                      child: Text("Don't have an account? Create one",
                          style: TextStyle(color: cs.secondary)),
                    ),
                  ).animate().fadeIn(delay: 480.ms),

                  const SizedBox(height: 8),
                  Text(
                    'Auto-lock after '
                    '${Constants.inactivityTimeoutSeconds}s of inactivity',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white24 : Colors.black26),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Blob widget ───────────────────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [BoxShadow(color: color, blurRadius: size / 2)],
        ),
      );
}
