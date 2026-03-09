import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';

import 'services/database_service.dart';
import 'services/email_otp_service.dart';
import 'services/encryption_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/key_storage_service.dart';
import 'services/session_service.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'viewmodels/todo_viewmodel.dart';
import 'views/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Screen protection ──────────────────────────────────────────────────────
  try { await ScreenProtector.preventScreenshotOn(); } catch (_) {}

  // ── Firebase ───────────────────────────────────────────────────────────────
  try {
    await Firebase.initializeApp();
    // ignore: avoid_print
    print('[main] Firebase initialized.');
  } catch (e) {
    // ignore: avoid_print
    print('[main] Firebase init skipped / failed: $e');
  }

  // ── Encrypted local DB ─────────────────────────────────────────────────────
  const secureStorage     = FlutterSecureStorage();
  final keyStorageService = KeyStorageService(secureStorage);
  final dbKey32           = await keyStorageService.getOrCreateDbKey32();

  final dbService      = DatabaseService(dbKey32);
  await dbService.init();

  final cryptoService  = EncryptionService(dbKey32);
  final sessionService = SessionService();

  // ── Theme ──────────────────────────────────────────────────────────────────
  final themeVm = ThemeViewModel();
  await themeVm.load();

  runApp(
    CipherTaskApp(
      keyStorageService: keyStorageService,
      databaseService:   dbService,
      encryptionService: cryptoService,
      sessionService:    sessionService,
      themeViewModel:    themeVm,
    ),
  );
}

class CipherTaskApp extends StatelessWidget {
  final KeyStorageService  keyStorageService;
  final DatabaseService    databaseService;
  final EncryptionService  encryptionService;
  final SessionService     sessionService;
  final ThemeViewModel     themeViewModel;

  const CipherTaskApp({
    super.key,
    required this.keyStorageService,
    required this.databaseService,
    required this.encryptionService,
    required this.sessionService,
    required this.themeViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<KeyStorageService>.value(value: keyStorageService),
        Provider<DatabaseService>.value(value: databaseService),
        Provider<EncryptionService>.value(value: encryptionService),
        Provider<EmailOtpService>(create: (_) => EmailOtpService()),
        Provider<FirebaseAuthService>(create: (_) => FirebaseAuthService()),
        ChangeNotifierProvider<SessionService>.value(value: sessionService),
        ChangeNotifierProvider<ThemeViewModel>.value(value: themeViewModel),

        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) {
            final vm = AuthViewModel(
              databaseService,
              keyStorageService,
              sessionService,
              ctx.read<EmailOtpService>(),
              ctx.read<FirebaseAuthService>(),
            );

            // ── Vibration timer (fires HapticFeedback every 800ms) ─────────
            Timer? _warningVibTimer;

            void _stopVibration() {
              _warningVibTimer?.cancel();
              _warningVibTimer = null;
            }

            void _startVibration() {
              _stopVibration();
              // Immediately vibrate once, then repeat every 800ms
              HapticFeedback.heavyImpact();
              _warningVibTimer = Timer.periodic(
                const Duration(milliseconds: 800),
                (_) => HapticFeedback.heavyImpact(),
              );
            }

            // ── Session callbacks ──────────────────────────────────────────
            sessionService.onWarningStart = () async {
              // Snackbar
              Constants.scaffoldMessengerKey.currentState
                ?..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    duration: Duration(seconds: Constants.sessionWarningSeconds),
                    content:  Text(
                      '⚠️  Session expires in 30 s – tap anywhere to stay signed in.',
                    ),
                  ),
                );
              // Vibrate
              _startVibration();
            };

            sessionService.onWarningDismiss = () async {
              Constants.scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
              _stopVibration();
            };

            sessionService.onTimeoutLock = () async {
              _stopVibration();
              Constants.scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
              vm.onSessionTimedOut();
              Constants.navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginView()),
                (_) => false,
              );
            };

            return vm;
          },
        ),

        ChangeNotifierProvider<TodoViewModel>(
          create: (_) => TodoViewModel(databaseService, encryptionService),
        ),
      ],

      child: Consumer<ThemeViewModel>(
        builder: (_, themeVm, __) => Listener(
          behavior:      HitTestBehavior.translucent,
          onPointerDown: (_) => sessionService.handleUserInteraction(),
          child: MaterialApp(
            navigatorKey:               Constants.navigatorKey,
            scaffoldMessengerKey:       Constants.scaffoldMessengerKey,
            debugShowCheckedModeBanner: false,
            title:     'CipherTask',
            theme:     AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeVm.mode,
            home:      const LoginView(),
          ),
        ),
      ),
    );
  }
}