# CommunityConnect — Frontend + Backend Integration Guide

## What changed from the original

| Area | Before | After |
|---|---|---|
| Auth | Fake delay, jumped to MainPage | Real POST /api/auth/login + /signup |
| Session | In-memory AppState with hardcoded data | JWT stored via shared_preferences, AppSession populated from API |
| Splash | Always went to AuthPage | Checks saved token → auto-login if valid |
| Home tab | Hardcoded event list | Loads featured event + user's organized events from API |
| Search tab | Filtered hardcoded list | Real-time search via GET /api/events/search |
| Notifications | Static hardcoded list | Live from GET /api/notifications, tap to mark read |
| Messages | Static chat list | Real chat threads + messages from API |
| Profile | Hardcoded user fields | Live from GET /api/users/profile with attended/organized counts |

---

## Setup

### 1. Start the backend
```bash
cd eventapp-backend
npm install
cp .env.example .env   # fill in JWT_SECRET and MONGO_URI
node server.js
```

### 2. Configure the API URL in Flutter
Open `lib/services/api_config.dart` and set `baseUrl`:

| Device | URL |
|---|---|
| Android emulator | `http://10.0.2.2:3000/api` ✅ (default) |
| iOS simulator | `http://localhost:3000/api` |
| Physical device | `http://YOUR_MACHINE_IP:3000/api` |

### 3. Install Flutter dependencies
```bash
flutter pub get
flutter run
```

---

## File structure added

```
lib/
├── main.dart                     ← Updated (real API calls throughout)
└── services/
    ├── api_config.dart           ← All endpoint URLs in one place
    ├── http_client.dart          ← Thin HTTP wrapper, auto-attaches JWT
    ├── token_service.dart        ← Saves/loads JWT via shared_preferences
    ├── auth_service.dart         ← signup / login / googleLogin / logout
    ├── event_service.dart        ← search / upcoming / featured / CRUD
    ├── user_service.dart         ← profile / attended / organized events
    ├── notification_service.dart ← get / markRead / markAllRead
    └── chat_service.dart         ← chatList / messages / sendMessage
```

---

## Google Sign-In (optional)

1. Add `google_sign_in: ^6.2.1` to pubspec.yaml
2. Follow setup at https://pub.dev/packages/google_sign_in
3. In `AuthPage`, replace the TODO button with:

```dart
import 'package:google_sign_in/google_sign_in.dart';

final _googleSignIn = GoogleSignIn();

Future<void> _handleGoogleSignIn() async {
  final account = await _googleSignIn.signIn();
  if (account == null) return;
  final auth = await account.authentication;
  final user = await AuthService.googleLogin(auth.idToken!);
  AppSession.user = user;
  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainPage()), (r) => false);
}
```
