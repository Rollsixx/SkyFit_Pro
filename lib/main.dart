import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';

import 'services/database_service.dart';
import 'services/encryption_service.dart';
import 'services/key_storage_service.dart';
import 'services/session_service.dart';
import 'utils/constants.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/todo_viewmodel.dart';
import 'views/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optional screenshot prevention (BONUS).
  // This does NOT use flutter_windowmanager.
  try {
    await ScreenProtector.preventScreenshotOn();
  } catch (_) {
    // If it fails on some platforms, app still runs.
  }

  const secureStorage = FlutterSecureStorage();
  final keyStorageService = KeyStorageService(secureStorage);
  final dbKey32 = await keyStorageService.getOrCreateDbKey32();

  final dbService = DatabaseService(dbKey32);
  await dbService.init();

  final cryptoService = EncryptionService(dbKey32);
  final sessionService = SessionService();

  runApp(
    CipherTaskApp(
      keyStorageService: keyStorageService,
      databaseService: dbService,
      encryptionService: cryptoService,
      sessionService: sessionService,
    ),
  );
}

class CipherTaskApp extends StatelessWidget {
  final KeyStorageService keyStorageService;
  final DatabaseService databaseService;
  final EncryptionService encryptionService;
  final SessionService sessionService;

  const CipherTaskApp({
    super.key,
    required this.keyStorageService,
    required this.databaseService,
    required this.encryptionService,
    required this.sessionService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<KeyStorageService>.value(value: keyStorageService),
        Provider<DatabaseService>.value(value: databaseService),
        Provider<EncryptionService>.value(value: encryptionService),
        ChangeNotifierProvider<SessionService>.value(value: sessionService),

        ChangeNotifierProvider<AuthViewModel>(
          create: (_) {
            final vm = AuthViewModel(databaseService, keyStorageService, sessionService);
            sessionService.onTimeoutLock = () {
              vm.onSessionTimedOut();
              // Force navigation back to login on timeout.
              final nav = Constants.navigatorKey.currentState;
              nav?.pushAndRemoveUntil(
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
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => sessionService.registerInteraction(),
        onPointerMove: (_) => sessionService.registerInteraction(),
        onPointerUp: (_) => sessionService.registerInteraction(),
        child: MaterialApp(
          navigatorKey: Constants.navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: Constants.dsBlack,
            colorScheme: ColorScheme.fromSeed(seedColor: Constants.dsCrimson, brightness: Brightness.dark),
            appBarTheme: const AppBarTheme(centerTitle: true),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: Colors.white.withOpacity(0.10),
              contentTextStyle: const TextStyle(color: Colors.white),
            ),
          ),
          home: const LoginView(),
        ),
      ),
    );
  }
}