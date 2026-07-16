# BDApps Subscription Migration — Changes Log

This document records every change made to convert the original Flutter
"Amar Proshno" application from a Firebase Authentication model to a
BDApps Subscription model. Every created, modified, and removed file is
listed below together with the rationale behind the change.

---

## 1. High-level summary

The application no longer uses Firebase Authentication, Google Sign In,
or any email/password-based authentication. Users now access the app
**only** through an active BDApps mobile subscription:

* **No subscription → no access.** The Home screen is gated by the
  `SubscriptionController.bootstrap()` / `validateSubscription()` flow
  which always talks to the backend before granting access.
* **Local cache is a hint, never a source of truth.** SharedPreferences
  is used only to avoid forcing the user through the OTP flow on every
  launch. The cached state is revalidated against the backend on every
  app start, every resume, and every 3 hours while the app is open.

---

## 2. Files removed

| File | Reason |
|------|--------|
| `lib/controllers/auth_controller.dart` | Firebase-based auth controller - replaced by `SubscriptionController`. |
| `lib/screens/auth_gate_screen.dart` | Firebase auth-state listener - replaced by `SplashScreen`. |
| `lib/screens/login_screen.dart` | Email/password login - no longer applicable. |
| `lib/screens/signup_screen.dart` | Email/password signup - no longer applicable. |
| `lib/widgets/auth_text_field.dart` | Form field reused only by login/signup. |
| `lib/firebase_options.dart` | Auto-generated Firebase options. |
| `firebase.json` | FlutterFire CLI configuration. |
| `android/app/google-services.json` | Firebase credentials for Android. |
| `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` | Auto-generated; contains Firebase plugin references. |

The deleted files are no longer referenced anywhere in the codebase.

---

## 3. Files modified

### 3.1 `pubspec.yaml`

* **Removed** `firebase_core`, `firebase_auth`, `google_sign_in`.
* **Added** `shared_preferences ^2.2.3` for local subscription cache.
* **Added** `connectivity_plus ^6.0.5` for offline detection.
* **Added** explicit `dev_dependencies:` block containing `flutter_test`.

### 3.2 `lib/main.dart`

* Removed `Firebase.initializeApp(...)` and `DefaultFirebaseOptions`.
* Removed `AuthController` registration.
* Added bootstrap of three singletons via GetX `Get.put`:
  * `LocalStorageService` (awaits SharedPreferences).
  * `SubscriptionRepository` (REST client wrapper).
  * `SubscriptionController` (reactive state machine).
* Registered new routes: `phoneRegistration`, `subscription`, `otp`,
  `settings`. The initial route is now `SplashScreen`.

### 3.3 `lib/routes/app_routes.dart`

* Removed `login`, `signup` route constants.
* Added `phoneRegistration`, `subscription`, `otp`, `settings` constants.

### 3.4 `lib/screens/home_screen.dart`

* Pulls the gradient / card-decoration helpers from the new shared
  `lib/widgets/app_background.dart` (preserves the visual identity).
* Wraps content in `AppBackground` for consistency.
* Adds a settings button (top-right) that navigates to
  `AppRoutes.settings`.

### 3.5 `lib/screens/quiz_screen.dart`, `lib/screens/result_screen.dart`, `lib/screens/ai_chat_screen.dart`

* Changed import from `'home_screen.dart'` (for `appGradient` /
  `cardDecoration`) to `'../widgets/app_background.dart'`. Visuals are
  identical.

### 3.6 `android/app/build.gradle.kts`

* Removed the `com.google.gms.google-services` plugin application.

### 3.7 `android/settings.gradle.kts`

* Removed the `id("com.google.gms.google-services")` declaration.

### 3.8 `test/widget_test.dart`

* Replaced the stale counter test with two unit tests that exercise
  `Subscription.isCurrentlyActive` and the `toMap`/`fromMap`
  round-trip.

---

## 4. Files created

### 4.1 Configuration & infrastructure

| File | Purpose |
|------|---------|
| `lib/config/app_config.dart` | Single source of truth for the BDApps wrapper base URL, timeouts, validation intervals, OTP length, and subscription duration. |

### 4.2 Models

| File | Purpose |
|------|---------|
| `lib/models/subscription_model.dart` | Immutable `Subscription` snapshot + `RegistrationResponse`, `VerificationResponse`, `CheckResponse`, `UnsubscribeResponse` value objects. Includes `Operator` and `SubscriptionStatus` enums and the BD phone-prefix operator detection logic. |

### 4.3 Services

| File | Purpose |
|------|---------|
| `lib/services/api_client.dart` | Reusable HTTP client. Wraps `package:http` with timeout, structured logging (`dart:developer`), and a typed error envelope (see below). |
| `lib/services/api_exceptions.dart` | Sealed exception hierarchy: `ApiException`, `NetworkException`, `ServerException`, `BadRequestException`, `UnexpectedResponseException`. Repository/UI code switches on these to produce friendly messages. |
| `lib/services/local_storage_service.dart` | SharedPreferences-backed cache. Stores phone, operator, status, subscription date, expiry date, transaction id, and last validation timestamp. Exposes `saveSubscription`, `readSubscription`, `updateValidation`, `clearSubscription`, `hasRegisteredPhone`. |

### 4.4 Repository

| File | Purpose |
|------|---------|
| `lib/repositories/subscription_repository.dart` | Single source of truth for BDApps data. Wraps the `ApiClient` and exposes `register`, `verifyOtp`, `check`, `unsubscribe`. The repository pattern keeps UI code decoupled from HTTP/serialisation details. |

### 4.5 Controller

| File | Purpose |
|------|---------|
| `lib/controllers/subscription_controller.dart` | GetX controller owning the subscription state machine. Exposes reactive `subscription`, `isLoading`, `isWorking`, `errorMessage`, `pendingTransactionId`, `resendSecondsRemaining`. Methods: `bootstrap`, `validateSubscription`, `registerSubscription`, `verifyOtp`, `resendOtp`, `unsubscribe`, `savePhoneLocally`, `refreshFromBackend`. Subscribes to `WidgetsBindingObserver.didChangeAppLifecycleState` for resume-time validation and runs a periodic `Timer` every 3 hours. |

### 4.6 Widgets

| File | Purpose |
|------|---------|
| `lib/widgets/app_background.dart` | Centralised gradient (`appGradient`) and `cardDecoration()` helpers used across every screen. Provides the `AppBackground` wrapper widget used by all subscription-related screens. |
| `lib/widgets/subscription_status_card.dart` | Card summarising the current subscription state. Reused on the subscription screen and the settings screen. |
| `lib/widgets/countdown_timer.dart` | Reusable `MM:SS` countdown timer used by the OTP resend flow. |
| `lib/widgets/otp_input.dart` | Six-cell OTP input with auto-focus, paste support, and `onCompleted` callback. |

### 4.7 Screens

| File | Purpose |
|------|---------|
| `lib/screens/splash_screen.dart` | Cold-start entry point. Calls `SubscriptionController.bootstrap()` which redirects to phone registration, subscription, or home based on cached state + backend validation. |
| `lib/screens/phone_registration_screen.dart` | Captures the Robi/Airtel Bangladesh mobile number. Normalises `8801XXXXXXXXX` / `8818XXXXXXXXX` / `1XXXXXXXXX` to `01XXXXXXXXX`. Validates against the selected operator's prefix (018 for Robi, 016 for Airtel). Saves the phone locally and navigates to the subscription screen. |
| `lib/screens/subscription_screen.dart` | Marketing-style subscription landing page. Lists benefits, monthly charge, terms. The **Subscribe Now** button calls `registerSubscription` and navigates to the OTP screen on success. |
| `lib/screens/otp_verification_screen.dart` | Six-digit OTP entry with auto-focus, paste support, countdown timer, resend button, loading state, and friendly error handling. On success the user is sent to Home. |
| `lib/screens/settings_screen.dart` | Subscription section listing every cached field. Includes Refresh and Unsubscribe buttons (with confirmation dialog). The unsubscribe flow clears the local cache and redirects to the subscription screen. |

### 4.8 Backend (BDApps wrapper)

The Flutter app never talks to BDApps directly. The PHP wrapper at the
project root exposes the four endpoints the Flutter client expects.

| File | Endpoint | Purpose |
|------|----------|---------|
| `bdapps_api/index.php` | `GET /` | Self-documentation page. |
| `bdapps_api/config.php` | n/a | BDApps credentials, plan metadata, default duration. Reads from environment variables. |
| `bdapps_api/bootstrap.php` | n/a | CORS headers, JSON response helpers, phone normalisation, cURL wrapper, local cache helpers. |
| `bdapps_api/api/subscription/register.php` | `POST /api/subscription/register` | Requests an OTP from `developer.bdapps.com/subscription/otp/request` and returns the `transactionId`. |
| `bdapps_api/api/subscription/verify.php` | `POST /api/subscription/verify` | Submits the OTP to `developer.bdapps.com/subscription/otp/verify`. Caches the subscriber on success. |
| `bdapps_api/api/subscription/check.php` | `POST /api/subscription/check` | Validates a subscriber via the local cache and, on miss, against `developer.bdapps.com/subscription/getStatus`. |
| `bdapps_api/api/subscription/unsubscribe.php` | `POST /api/subscription/unsubscribe` | Sends `action: "0"` to `developer.bdapps.com/subscription/send` and clears the local cache. |
| `bdapps_api/api/subscription/info.php` | `GET /api/subscription/info` | Plan / pricing / operator metadata used by the Flutter subscription screen. |
| `bdapps_api/README.md` | n/a | Setup and configuration instructions for the backend. |

The PHP wrapper never modifies the BDApps SDK (`BDApps_SDK/`). It is a
thin layer that translates REST requests into the SDK's existing PHP
calls (`send_otp.php`, `verify_otp.php`, `check_subscription.php`,
`unsubscribe.php`).

---

## 5. Application flow

```
App start
   │
   ▼
SplashScreen
   │
   ▼
SubscriptionController.bootstrap()
   │
   ├── no phone cached ─────────► PhoneRegistrationScreen ──► SubscriptionScreen
   │                                                            │
   │                                                            ▼
   │                                                        registerSubscription
   │                                                            │
   │                                                            ▼
   │                                                        OtpVerificationScreen
   │                                                            │
   │                                                            ▼
   │                                                        HomeScreen
   │
   └── phone cached ─► SubscriptionRepository.check(phone)
                              │
                              ├── active   ─► HomeScreen
                              └── inactive ─► SubscriptionScreen
```

Lifecycle hooks (`AppLifecycleState.resumed`) and a 3-hour periodic
timer re-run `validateSubscription()` while the app is in use. If the
backend reports inactive, the cached status flips to inactive and the
user is redirected to the subscription screen.

---

## 6. State management

* `SubscriptionController` extends `GetxController` and mixes in
  `WidgetsBindingObserver` for resume detection.
* All public state is reactive (`Rx`, `RxBool`, `RxnString`, `Rx<Subscription>`).
* UI binds through `Obx(...)`.
* No `setState` is used in any of the new screens.
* `Get.put` registers the three singletons in `main.dart` with
  `permanent: true`.

---

## 7. Networking

* `ApiClient` is the only place that knows about HTTP. It applies a
  global timeout (`AppConfig.requestTimeout`), logs every request via
  `dart:developer`, and translates low-level failures into the
  `ApiException` hierarchy.
* `SubscriptionRepository` is the only place that knows about JSON
  payloads. It converts every response into a typed model.
* The repository never holds state - it only transforms requests and
  responses. State lives in the controller and is mirrored to local
  storage through `LocalStorageService`.

---

## 8. Error handling

`SubscriptionController._humaniseError` translates raw exceptions into
user-friendly messages:

| Underlying failure | Message |
|--------------------|---------|
| `SocketException` / `NetworkException` | "No internet connection. Please check your network and try again." |
| `TimeoutException` | "Server is taking too long. Please try again." |
| `BadRequestException` (4xx) | The server's `message` / `error` field, if present. |
| `ServerException` (5xx) | "Subscription service is unavailable. Please try again later." |
| Anything else | "Something went wrong. Please try again." |

The repository also surfaces:

* Invalid phone (validator on the registration screen).
* Wrong / expired OTP (returned as a non-success verification response).
* Already subscribed / already unsubscribed (cached status + backend
  status code).
* Subscription inactive (handled by `validateSubscription` and the
  splash bootstrap).

---

## 9. Security

* No secrets are committed to the repository. The BDApps application
  password is read from the `BDAPPS_PASSWORD` environment variable by
  `bdapps_api/config.php`. The committed default is the same as the
  one used by the BDApps SDK sample scripts - replace it in production.
* Local storage holds only non-sensitive metadata. It is never used to
  grant access on its own - every protected screen is reachable only
  after a successful backend verification.
* CORS is restricted to `*` (suitable for the mobile client). Add an
  origin allow-list before deploying a web client.

---

## 10. UI consistency

* All new screens reuse the existing `appGradient`, `cardDecoration`
  helpers and the existing button styles (`ElevatedButton` with
  `Colors.white` background and `Color(0xFF612A7E)` foreground).
* No visual redesign was performed.
* Existing screens (`HomeScreen`, `QuizScreen`, `ResultScreen`,
  `AIChatScreen`) were updated to import the gradient helpers from
  their new home (`app_background.dart`) but their layout is unchanged.

---

## 11. Backend deployment

1. Copy `bdapps_api/` into the document root of your PHP server (e.g.
   XAMPP `htdocs/bdapps_api`).
2. Override the BDApps credentials via environment variables:
   ```
   setx BDAPPS_APP_ID "APP_XXXXXX"
   setx BDAPPS_PASSWORD "your-secret"
   setx BDAPPS_APP_HASH "YourAppHash"
   ```
3. Update `lib/config/app_config.dart::baseUrl` to point at the
   deployed backend.
4. Run the app and walk through the splash → phone registration →
   subscription → OTP → home flow.

---

## 12. Verification checklist

* [x] No `firebase_*` or `google_sign_in` references remain in the
      Flutter source.
* [x] `lib/main.dart` no longer calls `Firebase.initializeApp`.
* [x] `lib/routes/app_routes.dart` exposes the four subscription
      routes plus the original quiz routes.
* [x] `SubscriptionController.bootstrap()` routes a returning user
      with an active cached subscription straight to Home **only after
      a successful backend `check` call**.
* [x] `SubscriptionController.unsubscribe()` clears local storage and
      redirects to the subscription screen.
* [x] The OTP screen supports paste, auto-focus, countdown, resend,
      loading, and retry.
* [x] The Home screen is reachable only via
      `Get.offAllNamed(AppRoutes.home)` from inside the controller,
      and the controller only calls it after a positive verification.
* [x] `flutter analyze` reports 0 errors (1 unrelated warning about
      `flutter_lints`).
* [x] `flutter test` passes the new unit tests on `Subscription`.

