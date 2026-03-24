import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:vibration/vibration.dart';

import 'firebase_options.dart';
import 'services/database_service.dart';
import 'services/email_otp_service.dart';
import 'services/encryption_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_service.dart';
import 'services/key_storage_service.dart';
import 'services/local_auth_service.dart';
import 'services/session_manager.dart';
import 'services/storage_service.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'utils/env_config.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'viewmodels/user_viewmodel.dart';
import 'viewmodels/weather_viewmodel.dart';
import 'views/auth/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  EnvConfig.assertKeysPresent();

  //try {
  // await ScreenProtector.preventScreenshotOn();
  //} catch (_) {}

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // ignore: avoid_print
    print('[main] Firebase initialized.');
  } catch (e) {
    // ignore: avoid_print
    print('[main] Firebase init skipped: $e');
  }

  const secureStorage = FlutterSecureStorage();
  final keyStorageService = KeyStorageService(secureStorage);
  final storageService = StorageService(secureStorage);
  final dbKey32 = await keyStorageService.getOrCreateDbKey32();

  final dbService = DatabaseService(dbKey32);
  await dbService.init();

  final cryptoService = EncryptionService(dbKey32);
  final sessionManager = SessionManager();
  final localAuthService = LocalAuthService();

  final themeVm = ThemeViewModel();
  await themeVm.load();

  runApp(SkyFitApp(
    keyStorageService: keyStorageService,
    storageService: storageService,
    databaseService: dbService,
    encryptionService: cryptoService,
    sessionManager: sessionManager,
    localAuthService: localAuthService,
    themeViewModel: themeVm,
  ));
}

class SkyFitApp extends StatelessWidget {
  final KeyStorageService keyStorageService;
  final StorageService storageService;
  final DatabaseService databaseService;
  final EncryptionService encryptionService;
  final SessionManager sessionManager;
  final LocalAuthService localAuthService;
  final ThemeViewModel themeViewModel;

  const SkyFitApp({
    super.key,
    required this.keyStorageService,
    required this.storageService,
    required this.databaseService,
    required this.encryptionService,
    required this.sessionManager,
    required this.localAuthService,
    required this.themeViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<KeyStorageService>.value(value: keyStorageService),
        Provider<StorageService>.value(value: storageService),
        Provider<DatabaseService>.value(value: databaseService),
        Provider<EncryptionService>.value(value: encryptionService),
        Provider<LocalAuthService>.value(value: localAuthService),
        Provider<EmailOtpService>(create: (_) => EmailOtpService()),
        Provider<FirebaseAuthService>(create: (_) => FirebaseAuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProvider<SessionManager>.value(value: sessionManager),
        ChangeNotifierProvider<ThemeViewModel>.value(value: themeViewModel),

        // ── WeatherViewModel ─────────────────────────────────────────────────
        ChangeNotifierProvider<WeatherViewModel>(
          create: (_) => WeatherViewModel(),
        ),

        // ── UserViewModel ────────────────────────────────────────────────────
        ChangeNotifierProvider<UserViewModel>(
          create: (ctx) => UserViewModel(
            db: ctx.read<DatabaseService>(),
            firestore: ctx.read<FirestoreService>(),
          ),
        ),

        // ── AuthViewModel ────────────────────────────────────────────────────
        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) {
            final vm = AuthViewModel(
              databaseService,
              keyStorageService,
              sessionManager,
              ctx.read<EmailOtpService>(),
              ctx.read<FirebaseAuthService>(),
            );

            Timer? vibTimer;

            Future<void> stopVib() async {
              vibTimer?.cancel();
              vibTimer = null;
              try {
                await Vibration.cancel();
              } catch (_) {}
            }

            Future<void> startVib() async {
              await stopVib();
              final hasVib = await Vibration.hasVibrator() ?? false;
              if (!hasVib) {
                HapticFeedback.heavyImpact();
                vibTimer = Timer.periodic(
                  const Duration(milliseconds: 800),
                  (_) => HapticFeedback.heavyImpact(),
                );
                return;
              }
              final hasAmp = await Vibration.hasAmplitudeControl() ?? false;
              if (hasAmp) {
                Vibration.vibrate(
                  pattern: [0, 400, 400, 400, 400, 400],
                  intensities: [0, 255, 0, 200, 0, 180],
                  repeat: 0,
                );
              } else {
                Vibration.vibrate(pattern: [0, 500, 300], repeat: 0);
              }
            }

            sessionManager.onWarningStart = () async {
              Constants.scaffoldMessengerKey.currentState
                ?..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                  duration: Duration(seconds: Constants.sessionWarningSeconds),
                  content: Text(
                    '⚠️  Session expires in 60 s – tap anywhere to stay signed in.',
                  ),
                ));
              await startVib();
            };

            sessionManager.onWarningDismiss = () async {
              Constants.scaffoldMessengerKey.currentState
                  ?.hideCurrentSnackBar();
              await stopVib();
            };

            sessionManager.onTimeoutLock = () async {
              await stopVib();
              Constants.scaffoldMessengerKey.currentState
                  ?.hideCurrentSnackBar();
              vm.onSessionTimedOut();
              Constants.navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginView()),
                (_) => false,
              );
            };

            return vm;
          },
        ),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (_, themeVm, __) => Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => sessionManager.handleUserInteraction(),
          child: MaterialApp(
            navigatorKey: Constants.navigatorKey,
            scaffoldMessengerKey: Constants.scaffoldMessengerKey,
            debugShowCheckedModeBanner: false,
            title: 'SkyFit Pro',
            theme: AppTheme.light(themeVm.font),
            darkTheme: AppTheme.dark(themeVm.font),
            themeMode: themeVm.mode,
            home: const LoginView(),
          ),
        ),
      ),
    );
  }
}
