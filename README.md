# SkyFit Pro – Secure Health & Fitness App (Flutter, Strict MVVM)

**GitHub:** https://github.com/Rollsixx/SkyFit_Pro

**Live Web App:** https://skyfit-pro-635ab.web.app

---

## Team Members
- Rolly Boy Ryan Pionilla – Lead Architect & DB Engineer, Security & Cryptography Lead
- Angelo Padullon – Auth & Biometrics Specialist, Backend & Network (SSL)
- Jhonn Lee Maning – UI/UX & Integration

---

## About
SkyFit Pro is a secure personal health & fitness companion that suggests
personalized workout activities based on real-time weather data and user
profile (age & weight).

### Key Features
- Secure Registration with OTP Email Verification
- Google SSO with OTP second factor
- Biometric Authentication (Fingerprint) with 3-fail lockout
- Session auto-lock after 5 minutes of inactivity
- Real-time Weather via OpenWeatherMap API
- Personalized Activity Suggestions based on Weather + Age + Weight
- Encrypted local database (Hive + HiveAesCipher)
- AES-256-GCM field encryption for sensitive data
- Hardware-backed key storage (Android Keystore / iOS Keychain)
- Dark/Light mode toggle
- Profile management (Photo, Bio, Age, Weight, etc.)

---

## Strict MVVM Folder Structure

```
lib/
├── main.dart
├── models/
│   ├── user_model.dart
│   ├── weather_model.dart
│   └── activity_model.dart
├── views/
│   ├── auth/
│   │   ├── login_view.dart
│   │   └── register_view.dart
│   ├── home_view.dart
│   ├── profile_view.dart
│   └── widgets/
│       └── custom_button.dart
├── viewmodels/
│   ├── auth_viewmodel.dart
│   ├── user_viewmodel.dart
│   ├── theme_viewmodel.dart
│   └── weather_viewmodel.dart
├── repositories/
│   ├── auth_repository.dart
│   └── weather_repository.dart
├── services/
│   ├── api_service.dart
│   ├── database_service.dart
│   ├── email_otp_service.dart
│   ├── encryption_service.dart
│   ├── firebase_auth_service.dart
│   ├── firestore_service.dart
│   ├── key_storage_service.dart
│   ├── local_auth_service.dart
│   ├── session_service.dart
│   └── storage_service.dart
└── utils/
    ├── app_theme.dart
    ├── constants.dart
    └── env_config.dart
```

---

## Tech Stack
- Flutter
- Provider (state management)
- Hive + hive_flutter (encrypted local database)
- flutter_secure_storage (hardware-backed key storage)
- encrypt (AES-GCM)
- pointycastle (PBKDF2 password hashing)
- local_auth (biometrics)
- Firebase Auth (Google SSO + Email/Password)
- Cloud Firestore (user profile sync)
- OpenWeatherMap API (weather data)
- Geolocator (device location)
- EmailJS (OTP email delivery)
- screen_protector (screenshot prevention)

---

## Setup & Run Locally

### 1) Install dependencies
```bash
flutter pub get
```

### 2) Run with required API keys
```bash
flutter run \
  --dart-define=OPENWEATHER_API_KEY=your_key \
  --dart-define=EMAILJS_SERVICE_ID=your_id \
  --dart-define=EMAILJS_TEMPLATE_ID=your_template \
  --dart-define=EMAILJS_PUBLIC_KEY=your_public_key
```

### 3) Build APK
```bash
flutter build apk --release
```

### 4) Build Web
```bash
flutter build web --release
```

---

## Deployment

### Firebase Hosting
```bash
firebase deploy --only hosting
```

### Docker
```bash
docker build -t skyfit-pro .
docker run -p 8080:8080 skyfit-pro
```

---

## Security Features
- Encrypted database at rest (Hive + HiveAesCipher)
- AES-256-GCM encryption for sensitive fields
- No hardcoded encryption keys
- Session auto-lock after 5 minutes inactivity
- Biometric unlock (after first password login)
- PBKDF2 password hashing (100,000 iterations)

---

## Health Logic Algorithm

| Weather | Age | Weight | Suggested Activity |
|---------|-----|--------|--------------------|
| Clear/Sunny | < 50 | Normal | Outdoor Running / HIIT |
| Clear/Sunny | >= 50 | Any | Morning Walk / Tai Chi |
| Rain/Snow | Any | Any | Indoor Yoga / Bodyweight |
| Extreme Heat | Any | >= 90kg | Swimming / Light Stretching |
| Thunderstorm | Any | Any | Indoor Rest & Stretching |

---

## Security Disclaimer
This is a laboratory exercise demonstrating correct MVVM separation
and baseline secure patterns. For production use, add device integrity
checks, rate limiting, and key rotation.
