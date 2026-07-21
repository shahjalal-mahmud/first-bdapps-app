/// Centralized configuration for the BDApps Subscription gateway.
///
/// The PHP backend lives at the fixed production URL below and exposes
/// four endpoints under the gateway root:
///
///   * POST {baseUrl}/send_otp.php            body: user_mobile
///   * POST {baseUrl}/verify_otp.php          body: Otp, referenceNo
///   * POST {baseUrl}/check_subscription.php  body: user_mobile
///   * POST {baseUrl}/unsubscribe.php         body: user_mobile
///
/// The PHP scripts read from `$_POST`, so every Flutter request MUST
/// use `Content-Type: application/x-www-form-urlencoded` and pass the
/// body via `body: {...}`. Never use `jsonEncode` for these calls.
library;

class AppConfig {
  AppConfig._();

  /// Fixed base URL of the BDApps PHP backend.
  static const String baseUrl = 'https://bdappsdigitalapps.com/NADB26033';

  /// Total HTTP timeout when talking to the BDApps wrapper.
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Minimum interval between background subscription validations.
  static const Duration validationInterval = Duration(hours: 3);

  /// OTP resend cooldown.
  static const Duration otpResendCooldown = Duration(seconds: 60);
}