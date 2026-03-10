import 'package:flutter/material.dart';

class Constants {
  // ── Session ────────────────────────────────────────────────────────────────
  static const int inactivityTimeoutSeconds = 120;
  static const int sessionWarningSeconds    = 30;

  // ── Secure Storage Keys ────────────────────────────────────────────────────
  static const String secureDbKey      = 'CIPHERTASK_SECURE_DB_KEY_V1';
  static const String secureLastEmail  = 'CIPHERTASK_LAST_EMAIL_V1';

  // ── Hive Boxes ─────────────────────────────────────────────────────────────
  static const String usersBox = 'cipher_users_box_v1';
  static const String todosBox = 'cipher_todos_box_v1';

  // ── Crypto Labels ──────────────────────────────────────────────────────────
  static const String fieldKeyLabel        = 'CIPHERTASK_FIELD_KEY_V1';
  static const String aesGcmPayloadVersion = 'v1';

  // ── EmailJS ────────────────────────────────────────────────────────────────
  static const String emailJsServiceId  = 'service_iqgzdip';
  static const String emailJsTemplateId = 'template_3bxocc1';
  static const String emailJsPublicKey  = 'x1Fhyl6aKSVMEHgoZ';

  // ── Navigation / UI ────────────────────────────────────────────────────────
  static final GlobalKey<NavigatorState>         navigatorKey         =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // ── Dark Scheme ────────────────────────────────────────────────────────────
  static const Color dsBlack   = Color(0xFF0B0B0F);
  static const Color dsSurface = Color(0xFF16161E);
  static const Color dsCrimson = Color(0xFFB11226);
  static const Color dsTeal    = Color(0xFF1AA6B7);

  // ── Light Scheme ───────────────────────────────────────────────────────────
  static const Color lsBackground = Color(0xFFF5F5F8);
  static const Color lsSurface    = Color(0xFFFFFFFF);
  static const Color lsPrimary    = Color(0xFFB11226);
  static const Color lsAccent     = Color(0xFF1AA6B7);

  // ── Priority colours ───────────────────────────────────────────────────────
  static const Color prioHigh   = Color(0xFFE53935);
  static const Color prioMedium = Color(0xFFFB8C00);
  static const Color prioLow    = Color(0xFF43A047);
}