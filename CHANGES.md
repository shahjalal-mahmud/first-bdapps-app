# BDApps Subscription Migration — Changes Log

This document records every change made to convert the original Flutter
"Amar Proshno" application from a Firebase Authentication model to a
BDApps Subscription model that talks directly to the existing production
PHP backend in `BDApps_SDK/`.

---

## 1. High-level summary

The application no longer uses Firebase Authentication, Google Sign In,
or any email/password-based authentication. Users now access the app
**only** through an active BDApps mobile subscription:

- **No subscription → no access.** The Home screen is gated by
  `SubscriptionController.bootstrap()` / `validateSubscription()`, which
  always talks to the backend before granting access.
- **Local cache is a hint, never a source of truth.** `SharedPreferences`
  is used only to avoid forcing the user through the OTP flow on every
  launch. The cached state is revalidated against the backend on every
  app start, every resume, on manual refresh, and every 3 hours while
  the app is open.
- **The backend is fixed.** Flutter talks only to the four production
  PHP scripts (`send_otp.php`, `verify_otp.php`, `check_subscription.php`,
  `unsubscribe.php`) under `https://bdappsdigitalapps.com/NADB26033/`. They are
  never modified, renamed, or replaced.

---

## 2. Phases of the migration

The migration was performed in two passes:

- **Phase 1 — Firebase → custom BDApps wrapper.** The original Flutter
  app used Firebase Auth (email/password + Google Sign-In). This was
  replaced by a custom PHP REST wrapper that exposed four
  `/api/subscription/*` endpoints. The Flutter app called those
  endpoints with JSON.
- **Phase 2 — Custom wrapper → existing `BDApps_SDK/` PHP endpoints.**
  The custom wrapper was abandoned in favour of the existing production
  PHP scripts in `BDApps_SDK/`, which read from `$_POST` (form-encoded)
  rather than JSON. The Flutter app was rewritten to match this exact
  contract: form-urlencoded requests, exact field names, and the real
  response shape.
- **Phase 3 — Dead-code cleanup.** Unused files, parameters, methods,
  and dependencies were removed.

The rest of this document focuses on the current state of the project
(Phase 2 + Phase 3) and lists the changes that landed in each phase.

---

## 3. Phase 1 — Firebase → custom BDApps wrapper

### 3.1 Files removed

| File                                                                          | Reason                                                           |
|-------------------------------------------------------------------------------|------------------------------------------------------------------|
| `lib/controllers/auth_controller.dart`                                        | Firebase auth controller — replaced by `SubscriptionController`. |
| `lib/screens/auth_gate_screen.dart`                                           | Firebase auth-state listener — replaced by `SplashScreen`.       |
| `lib/screens/login_screen.dart`                                               | Email/password login — no longer applicable.                     |
| `lib/screens/signup_screen.dart`                                              | Email/password signup — no longer applicable.                    |
| `lib/widgets/auth_text_field.dart`                                            | Form field reused only by login/signup.                          |
| `lib/widgets/primary_button.dart`                                             | Used only by auth screens.                                       |
| `lib/widgets/progress_bar.dart`                                               | Used only by auth screens.                                       |
| `lib/widgets/question_card.dart`                                              | Replaced by inline card in `QuizScreen`.                         |
| `lib/firebase_options.dart`                                                   | Auto-generated Firebase options.                                 |
| `firebase.json`                                                               | FlutterFire CLI configuration.                                   |
| `android/app/google-services.json`                                            | Firebase credentials for Android.                                |
| `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` | Auto-generated; contained Firebase plugin references.            |

The deleted files are no longer referenced anywhere in the codebase.

### 3.2 `pubspec.yaml`

- **Removed** `firebase_core`, `firebase_auth`, `google_sign_in`.
- **Added** `shared_preferences ^2.2.3` for the local subscription cache.
- **Added** `http ^1.2.0` for the custom REST wrapper.

### 3.3 `lib/main.dart`

- Removed `Firebase.initializeApp(...)` and `DefaultFirebaseOptions`.
- Removed `AuthController` registration.
- Added bootstrap of three singletons via GetX `Get.put`:
  - `LocalStorageService` (awaits SharedPreferences).
  - `SubscriptionRepository` (REST client wrapper).
  - `SubscriptionController` (reactive state machine).
- Registered new routes: `phoneRegistration`, `subscription`, `otp`,
  `settings`. The initial route is now `SplashScreen`.

### 3.4 `lib/routes/app_routes.dart`

- Removed `login`, `signup` route constants.
- Added `phoneRegistration`, `subscription`, `otp`, `settings` constants.

### 3.5 `lib/screens/home_screen.dart`

- Pulled the gradient / card-decoration helpers from the new shared
  `lib/widgets/app_background.dart` (preserved the visual identity).
- Wrapped content in `AppBackground` for consistency.
- Added a Settings button (top-right) that navigates to
  `AppRoutes.settings`.

### 3.6 `lib/screens/quiz_screen.dart`, `lib/screens/result_screen.dart`, `lib/screens/ai_chat_screen.dart`

- Changed import from `'home_screen.dart'` (for `appGradient` /
  `cardDecoration`) to `'../widgets/app_background.dart'`. Visuals are
  identical.

### 3.7 `android/app/build.gradle.kts`

- Removed the `com.google.gms.google-services` plugin application.

### 3.8 `android/settings.gradle.kts`

- Removed the `id("com.google.gms.google-services")` declaration.

### 3.9 `test/widget_test.dart`

- Replaced the stale counter test with unit tests that exercise the
  `Subscription` model.

### 3.10 Phase 1 — created files

| File                                            | Purpose                                                                                                                                   |
|-------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| `lib/config/app_config.dart`                    | Single source of truth for the BDApps wrapper base URL, timeouts, validation intervals, OTP length, and subscription duration.            |
| `lib/models/subscription_model.dart`            | Immutable `Subscription` snapshot + `RegistrationResponse`, `VerificationResponse`, `CheckResponse`, `UnsubscribeResponse` value objects. |
| `lib/services/api_client.dart`                  | Reusable HTTP client wrapping `package:http` with timeout, structured logging, and a typed error envelope. **Deleted in Phase 2.**        |
| `lib/services/api_exceptions.dart`              | Sealed exception hierarchy: `ApiException`, `NetworkException`, `ServerException`, `BadRequestException`, `UnexpectedResponseException`.  |
| `lib/services/local_storage_service.dart`       | SharedPreferences-backed cache.                                                                                                           |
| `lib/repositories/subscription_repository.dart` | Single source of truth for BDApps data. **Deleted in Phase 2.**                                                                           |
| `lib/controllers/subscription_controller.dart`  | GetX controller owning the subscription state machine.                                                                                    |
| `lib/widgets/app_background.dart`               | Centralised gradient (`appGradient`) and `cardDecoration()` helpers + the `AppBackground` wrapper widget.                                 |
| `lib/widgets/subscription_status_card.dart`     | Card summarising the current subscription state.                                                                                          |
| `lib/widgets/countdown_timer.dart`              | Reusable `MM:SS` countdown timer for the OTP resend flow.                                                                                 |
| `lib/widgets/otp_input.dart`                    | Six-cell OTP input with auto-focus, paste support, and `onCompleted` callback.                                                            |
| `lib/screens/splash_screen.dart`                | Cold-start entry point.                                                                                                                   |
| `lib/screens/phone_registration_screen.dart`    | Captures the Robi/Airtel Bangladesh mobile number.                                                                                        |
| `lib/screens/subscription_screen.dart`          | Marketing-style subscription landing page.                                                                                                |
| `lib/screens/otp_verification_screen.dart`      | Six-digit OTP entry with auto-focus, paste support, countdown, resend, loading, and error handling.                                       |
| `lib/screens/settings_screen.dart`              | Subscription section listing every cached field, with Refresh and Unsubscribe buttons.                                                    |

---

## 4. Phase 2 — Custom wrapper → existing `BDApps_SDK/` PHP endpoints

The custom PHP wrapper introduced in Phase 1 was abandoned. The Flutter
app now talks directly to the existing production PHP scripts in
`BDApps_SDK/`. The custom endpoints `/api/subscription/register`,
`/api/subscription/verify`, `/api/subscription/check`,
`/api/subscription/unsubscribe` are gone; nothing in the Flutter codebase
references them anymore.

### 4.1 Endpoint contract

| Endpoint           | URL                                                              | Method | Body (`application/x-www-form-urlencoded`) |
|--------------------|------------------------------------------------------------------|--------|--------------------------------------------|
| Send OTP           | `https://bdappsdigitalapps.com/NADB26033/send_otp.php`           | `POST` | `user_mobile`                              |
| Verify OTP         | `https://bdappsdigitalapps.com/NADB26033/verify_otp.php`         | `POST` | `Otp` (capital O), `referenceNo`           |
| Check Subscription | `https://bdappsdigitalapps.com/NADB26033/check_subscription.php` | `POST` | `user_mobile`                              |
| Unsubscribe        | `https://bdappsdigitalapps.com/NADB26033/unsubscribe.php`        | `POST` | `user_mobile`                              |

The PHP scripts read from `$_POST`. JSON bodies are ignored. Every
Flutter request uses `Content-Type: application/x-www-form-urlencoded`
and passes the body via `http.Client.post(url, body: {...})` — never via
`jsonEncode`.

### 4.2 Files created in Phase 2

| File                                     | Purpose                                                                                                                                                                                                                                                                                                |
|------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `lib/services/bdapps_service.dart`       | **The single HTTP service** for the four BDApps endpoints. Form-urlencoded POSTs only, with timeout, structured logging, and the typed exception envelope from `api_exceptions.dart`. Methods: `sendOtp(mobile)`, `verifyOtp({otp, referenceNo})`, `checkSubscription(mobile)`, `unsubscribe(mobile)`. |
| `lib/models/bdapps_response_models.dart` | Typed responses for the four endpoints: `SendOtpResponse`, `VerifyOtpResponse`, `SubscriptionStatusResponse`, `UnsubscribeResponse`. Each `fromJson` mirrors the exact field set the corresponding PHP script emits.                                                                                   |

### 4.3 Files modified in Phase 2

#### `lib/config/app_config.dart`
- `baseUrl` changed to the fixed production value
  `https://bdappsdigitalapps.com/NADB26033`.
- Removed `apiPrefix` (no more `/api/subscription/*` paths).
- Removed `subscriptionDurationDays` (no longer needed).

#### `lib/services/local_storage_service.dart`
- Slimmed to the four fields the backend actually exposes:
  `phone`, `subscriberId`, `subscriptionStatus`, `lastValidationTime`.
- Removed `updateValidation` (no longer needed; the controller writes the
  full snapshot).

#### `lib/models/subscription_model.dart`
- `Subscription` now has `phone`, `subscriberId`, `status`, `operator`,
  `lastValidationTime`. Removed `subscriptionDate`, `expiryDate`,
  `transactionId`.
- `SubscriptionStatus` enum is now `{registered, unregistered, unknown}`,
  with the registered/unregistered values matching the BDApps strings.
- Removed the `RegistrationResponse`, `VerificationResponse`,
  `CheckResponse`, `UnsubscribeResponse` value objects from this file —
  they live in `bdapps_response_models.dart` now and match the real PHP
  responses.

#### `lib/controllers/subscription_controller.dart`
- No longer depends on `SubscriptionRepository`. Talks to `BdappsService`
  directly.
- `bootstrap()` and `validateSubscription()` call
  `BdappsService.checkSubscription(phone)`. They route to Home **only**
  when the backend reports `REGISTERED`. On `UNREGISTERED` the local
  cache is cleared and the user is redirected to the Subscription screen.
- `registerSubscription` was renamed to `sendOtp` and now returns a
  `SendOtpResponse`.
- `verifyOtp` now takes the OTP directly (no longer a `transactionId`
  parameter — internally uses `pendingReferenceNo`) and returns a
  `VerifyOtpResponse` whose `isRegistered` property decides whether to
  save the `subscriberId` locally.
- `unsubscribe` calls `BdappsService.unsubscribe(phone)`; on success (or
  failure) the local cache is wiped and the user is redirected.
- `savePhoneLocally` was removed (Phase 3).
- All `Registration`/`Verification`/`Check`/`Unsubscribe` JSON models
  were removed in favour of the new typed responses in
  `bdapps_response_models.dart`.

#### `lib/main.dart`
- Removed the `SubscriptionRepository` registration.
- Added a `BdappsService` registration as a permanent singleton.
- `SubscriptionController` is now constructed with the service instead of
  a repository.

#### `lib/screens/phone_registration_screen.dart`
- The **Continue** button now calls `controller.sendOtp(phone)` directly
  (instead of saving locally then navigating to the Subscription screen).
- Navigates to the OTP screen only after `send_otp.php` returns a
  `referenceNo`.

#### `lib/screens/subscription_screen.dart`
- **Subscribe Now** calls `controller.sendOtp(phone)` and navigates to
  the OTP screen on a returned `referenceNo`.

#### `lib/screens/otp_verification_screen.dart`
- Uses `VerifyOtpResponse.isRegistered` (instead of the old
  `response.subscriptionActive`) to decide whether to navigate to Home.

#### `lib/screens/settings_screen.dart`
- Uses `subscription.status.isRegistered` (instead of the removed
  `isCurrentlyActive`).

#### `lib/widgets/subscription_status_card.dart`
- Shows phone, subscriber, last checked (instead of the removed
  `subscriptionDate` / `expiryDate` fields).

#### `test/widget_test.dart`
- Rewritten against the new `Subscription` shape (`subscriberId`,
  `lastValidationTime`, `status.registered` / `unregistered`).

### 4.4 Files deleted in Phase 2

| File                                            | Reason                                                                                                                                   |
|-------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------|
| `lib/repositories/subscription_repository.dart` | Replaced by `BdappsService`. The repository pattern added no value once the service was allowed to be the single source of HTTP traffic. |
| `lib/services/api_client.dart`                  | Replaced by `BdappsService`. The generic JSON client was only ever used by the deleted repository.                                       |

The `bdapps_api/` directory created in Phase 1 was also removed in Phase
2 — it is no longer needed because the Flutter app talks directly to the
production PHP scripts in `BDApps_SDK/`.

### 4.5 `android/app/src/main/AndroidManifest.xml`
- Added `<uses-permission android:name="android.permission.INTERNET"/>` so
  the device can reach `https://bdappsdigitalapps.com/NADB26033/`.

---

## 5. Phase 3 — Dead-code cleanup

A targeted pass to remove every piece of code or dependency that was no
longer referenced anywhere in `lib/`.

| Item                                      | Type               | Evidence                                                                                           |
|-------------------------------------------|--------------------|----------------------------------------------------------------------------------------------------|
| `connectivity_plus: ^6.0.5`               | Pubspec dependency | Imported nowhere in `lib/`; only listed in `pubspec.yaml` and `pubspec.lock`.                      |
| `AppConfig.otpLength`                     | Constant           | Defined but never referenced. The OTP widget uses its own literal default of `6`.                  |
| `SubscriptionController.savePhoneLocally` | Method             | Dead since the phone-registration screen now calls `sendOtp` directly.                             |
| `SubscriptionStatusCard.compact`          | Widget parameter   | Both call sites omit it; default is unused. Also removed the now-dead `compact ? 12 : 16` ternary. |

All remaining files, classes, methods, and constants were verified to be
reachable from `main.dart` before deletion.

---

## 6. Application flow (current)

```
App start
   │
   ▼
SplashScreen
   │
   ▼
SubscriptionController.bootstrap()
   │
   ├── no phone cached ────────► PhoneRegistrationScreen
   │                                     │
   │                                     ▼
   │                              sendOtp (send_otp.php)
   │                                     │
   │                                     ▼
   │                             OtpVerificationScreen
   │                                     │
   │                                     ▼
   │                              verifyOtp (verify_otp.php)
   │                                     │
   │                              REGISTERED?
   │                                     │
   │                                  Yes
   │                                     ▼
   │                                  Home
   │
   └── phone cached ──► checkSubscription (check_subscription.php)
                              │
                              ├── REGISTERED ──► Home
                              └── UNREGISTERED ─► clear cache ─► Subscription
                                                          │
                                                          └── (same flow as above)
```

Lifecycle hooks (`AppLifecycleState.resumed`) and a 3-hour periodic
timer re-run `validateSubscription()` while the app is in use. If the
backend reports `UNREGISTERED`, the local cache is cleared and the user
is redirected to the Subscription screen.

---

## 7. State management (current)

- `SubscriptionController` extends `GetxController` and mixes in
  `WidgetsBindingObserver` for resume detection.
- All public state is reactive (`Rx`, `RxBool`, `RxnString`, `RxInt`,
  `Rx<Subscription>`).
- UI binds through `Obx(...)`.
- No `setState` is used in any of the subscription screens.
- `Get.put` registers the three singletons in `main.dart` with
  `permanent: true`.

---

## 8. Networking (current)

- `BdappsService` is the only place in the codebase that issues HTTP
  requests against the BDApps gateway.
- Every request is `application/x-www-form-urlencoded` with the body
  passed via `body: {...}` (no `jsonEncode`, no JSON content-type).
- A global timeout (`AppConfig.requestTimeout`) applies to every call.
- `dart:developer` logs every request and response for debugging.
- `api_exceptions.dart` is the typed error envelope thrown out of the
  service. `SubscriptionController._humaniseError` turns each into a
  user-friendly message.

---

## 9. Error handling (current)

`SubscriptionController._humaniseError` translates raw exceptions into
user-friendly messages:

| Underlying failure                     | Message                                                            |
|----------------------------------------|--------------------------------------------------------------------|
| `SocketException` / `NetworkException` | "No internet connection. Please check your network and try again." |
| `TimeoutException` / "timed out"       | "Server is taking too long. Please try again."                     |
| `BadRequestException` (4xx)            | The server's `message` / `error` field, if present.                |
| `ServerException` (5xx)                | "Subscription service is unavailable. Please try again later."     |
| Anything else                          | "Something went wrong. Please try again."                          |

The service also handles:
- **Invalid phone** — caught by the registration screen validator and
  rejected server-side ("Invalid mobile number format").
- **Wrong / expired OTP** — `verify_otp.php` returns
  `statusCode != S1000`; the controller surfaces the `statusDetail`.
- **Subscription inactive** — handled by `validateSubscription` and the
  splash bootstrap.

---

## 10. Security (current)

- No secrets are committed to the repository. The BDApps application
  credentials live in the PHP backend, never in Flutter.
- Local storage holds only the four non-sensitive fields the backend
  exposes. It is never used to grant access on its own — every protected
  screen is reachable only after a successful backend verification.
- The Home screen is reachable **only** via
  `Get.offAllNamed(AppRoutes.home)` from inside `SubscriptionController`,
  and only when the backend has confirmed `REGISTERED`.
- On `UNREGISTERED`, the local cache is wiped and the user is redirected
  to the Subscription screen.

---

## 11. Backend deployment

The PHP backend lives in `BDApps_SDK/` at the project root and is also
mirrored on the production host at `https://bdappsdigitalapps.com/NADB26033/`.
**Neither copy is modified by the Flutter project.**

The Flutter app does not deploy or configure the backend — it only
configures the URL in `lib/config/app_config.dart::AppConfig.baseUrl`,
which is fixed at `https://bdappsdigitalapps.com/NADB26033`.

---

## 12. Verification checklist

- [x] No `firebase_*` or `google_sign_in` references remain in the
      Flutter source.
- [x] `lib/main.dart` no longer calls `Firebase.initializeApp`.
- [x] No references to the deleted custom endpoints
      (`/api/subscription/{register,verify,check,unsubscribe}`) remain.
- [x] No `jsonEncode` is used to talk to the BDApps gateway.
- [x] `BdappsService` is the only file in `lib/` that issues HTTP
      requests against the BDApps gateway.
- [x] Every request uses
      `Content-Type: application/x-www-form-urlencoded` and `body: {...}`.
- [x] Verify OTP body uses `Otp` (capital O) and `referenceNo`,
      matching `verify_otp.php`.
- [x] Send OTP / Check / Unsubscribe bodies use `user_mobile`.
- [x] `SubscriptionController.bootstrap()` routes a returning user
      straight to Home **only after** the backend returns `REGISTERED`.
- [x] `SubscriptionController.validateSubscription()` clears the local
      cache and redirects to the Subscription screen on `UNREGISTERED`.
- [x] `SubscriptionController.unsubscribe()` clears the local cache and
      redirects to the Subscription screen.
- [x] The OTP screen supports paste, auto-focus, countdown, resend,
      loading, and retry.
- [x] `flutter analyze` reports 0 errors (1 unrelated warning about
      `flutter_lints`).
- [x] `flutter test` passes the new unit tests on `Subscription`.