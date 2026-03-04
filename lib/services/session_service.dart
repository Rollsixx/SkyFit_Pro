import 'dart:async';

import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class SessionService extends ChangeNotifier {
  Timer? _timer;
  bool _locked = true;

  bool get isLocked => _locked;

  VoidCallback? onTimeoutLock;

  void unlockSession() {
    _locked = false;
    _restartTimer();
    notifyListeners();
  }

  void lockSession() {
    _locked = true;
    _timer?.cancel();
    notifyListeners();
  }

  void registerInteraction() {
    if (_locked) return;
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer(
      const Duration(seconds: Constants.inactivityTimeoutSeconds),
      () {
        lockSession();
        onTimeoutLock?.call();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}