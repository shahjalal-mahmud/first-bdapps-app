import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../config/app_config.dart';
import '../models/bdapps_response_models.dart';
import '../models/subscription_model.dart';
import '../routes/app_routes.dart';
import '../services/bdapps_service.dart';
import '../services/local_storage_service.dart';

/// GetX controller that owns the global subscription state machine.
///
/// Exposes a reactive [subscription] field that every screen watches
/// through [Obx]. All mutations are funnelled through the methods on
/// this controller so that loading flags, error messages, and the local
/// cache stay in sync.
///
/// Routing rule (per spec): **the Home screen must never open unless
/// `subscriptionStatus == REGISTERED`**. We always re-check this with
/// the backend on app startup, on resume, and on manual refresh.
class SubscriptionController extends GetxController
    with WidgetsBindingObserver {
  final BdappsService _service;
  final LocalStorageService _storage;

  SubscriptionController({
    required BdappsService service,
    required LocalStorageService storage,
  }) : _service = service,
       _storage = storage;

  // ---------------------------------------------------------------------------
  // Reactive state
  // ---------------------------------------------------------------------------

  /// Cached subscription state. The UI binds to this through `Obx`.
  final Rx<Subscription> subscription = Subscription.empty.obs;

  /// Generic spinner flag for in-flight REST calls.
  final RxBool isLoading = false.obs;

  /// True while a sendOtp/verifyOtp round-trip is in progress.
  final RxBool isWorking = false.obs;

  /// Last error message produced by an API call (UI may bind to this).
  final Rx<String?> errorMessage = Rx<String?>(null);

  /// Most recent OTP request's reference number.
  final RxnString pendingReferenceNo = RxnString();

  /// Set to true when the controller redirects to home/subscription/etc.
  /// Screens read this to avoid double-navigating on rebuild.
  final RxBool hasNavigated = false.obs;

  /// Timer used by the OTP screen to display a "Resend" countdown.
  final RxInt resendSecondsRemaining = 0.obs;

  Timer? _resendTimer;
  Timer? _backgroundValidator;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    subscription.value = _storage.readSubscription();
    WidgetsBinding.instance.addObserver(this);
    _scheduleBackgroundValidation();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _resendTimer?.cancel();
    _backgroundValidator?.cancel();
    super.onClose();
  }

  /// Triggered when the app is resumed from background. We re-validate
  /// the subscription with the backend so the user can never linger
  /// inside Home after their subscription was cancelled upstream.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_storage.hasRegisteredPhone()) {
        validateSubscription(silent: true);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Performs the splash bootstrap:
  ///
  ///   1. If no phone is cached locally -> Phone Registration.
  ///   2. Otherwise call `check_subscription.php`.
  ///   3. Redirect to Home (REGISTERED) or Subscription (anything else).
  ///
  /// Returns the resulting subscription so the splash screen can react
  /// to the final state if needed.
  Future<Subscription> bootstrap() async {
    hasNavigated.value = false;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      if (!_storage.hasRegisteredPhone()) {
        _navigateTo(AppRoutes.phoneRegistration);
        return subscription.value;
      }

      final phone = subscription.value.phone;
      final status = await _service.checkSubscription(phone);
      final updated = _applyStatus(subscription.value, status);

      if (updated.status.isRegistered) {
        _navigateTo(AppRoutes.home);
      } else {
        // Backend says UNREGISTERED. Wipe local cache and force the user
        // through the subscription flow.
        await _storage.clearSubscription();
        subscription.value = Subscription.empty;
        _navigateTo(AppRoutes.subscription);
      }
      return subscription.value;
    } catch (e, st) {
      developer.log(
        'Bootstrap failed',
        name: 'SubscriptionController',
        error: e,
        stackTrace: st,
      );
      errorMessage.value = _humaniseError(e);
      // On any backend failure we degrade to the local cache. If the
      // cache shows REGISTERED, grant access; otherwise route to the
      // subscription screen.
      if (subscription.value.status.isRegistered) {
        _navigateTo(AppRoutes.home);
      } else {
        _navigateTo(AppRoutes.subscription);
      }
      return subscription.value;
    } finally {
      isLoading.value = false;
    }
  }

  /// Validates the cached subscription against the backend.
  ///
  /// On UNREGISTERED the local cache is cleared and the user is sent to
  /// the subscription screen. Returns the latest cached status.
  Future<bool> validateSubscription({bool silent = false}) async {
    if (!_storage.hasRegisteredPhone()) return false;
    if (!silent) isLoading.value = true;
    errorMessage.value = null;

    try {
      final phone = subscription.value.phone;
      final status = await _service.checkSubscription(phone);
      final updated = _applyStatus(subscription.value, status);

      if (updated.status.isRegistered) {
        subscription.value = updated;
        await _storage.saveSubscription(updated);
        return true;
      }

      // Backend says we are not subscribed - wipe the local cache and
      // redirect the user to the subscription screen.
      await _storage.clearSubscription();
      subscription.value = Subscription.empty;
      pendingReferenceNo.value = null;
      _navigateTo(AppRoutes.subscription);
      return false;
    } catch (e) {
      developer.log(
        'Validation failed',
        name: 'SubscriptionController',
        error: e,
      );
      if (!silent) errorMessage.value = _humaniseError(e);
      // On network failure during a silent validation we keep the
      // cached state - we do not kick the user out just because they
      // momentarily lost connectivity.
      return subscription.value.status.isRegistered;
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  /// Step 1 of the subscription flow. Calls `send_otp.php` and stores
  /// the returned `referenceNo` so the next screen can submit it.
  Future<SendOtpResponse> sendOtp(String phone) async {
    isWorking.value = true;
    errorMessage.value = null;
    try {
      final response = await _service.sendOtp(phone);
      if (!response.success ||
          response.referenceNo == null ||
          response.referenceNo!.isEmpty) {
        errorMessage.value = response.message ??
            'Could not start subscription. Please try again.';
        return response;
      }
      pendingReferenceNo.value = response.referenceNo;
      _startResendCooldown();

      // Persist the phone we are trying to subscribe with. We do not
      // have a subscriberId yet (it is returned by verify_otp.php).
      final provisional = subscription.value.copyWith(
        phone: phone,
        subscriberId: response.subscriberId ?? subscription.value.subscriberId,
        operator: detectOperator(phone),
        status: SubscriptionStatus.unknown,
        lastValidationTime: DateTime.now(),
      );
      subscription.value = provisional;
      await _storage.saveSubscription(provisional);
      return response;
    } catch (e) {
      errorMessage.value = _humaniseError(e);
      rethrow;
    } finally {
      isWorking.value = false;
    }
  }

  /// Step 2 of the subscription flow. Submits the OTP to
  /// `verify_otp.php`. On `REGISTERED` we save the subscriberId locally
  /// and let the caller navigate to Home.
  Future<VerifyOtpResponse> verifyOtp(String otp) async {
    final referenceNo = pendingReferenceNo.value;
    if (referenceNo == null || referenceNo.isEmpty) {
      const msg = 'No active subscription request. Please try again.';
      errorMessage.value = msg;
      throw StateError(msg);
    }
    isWorking.value = true;
    errorMessage.value = null;
    try {
      final response = await _service.verifyOtp(
        otp: otp,
        referenceNo: referenceNo,
      );
      if (!response.isRegistered) {
        errorMessage.value = response.statusDetail.isNotEmpty
            ? response.statusDetail
            : 'OTP verification failed. Please try again.';
        return response;
      }
      final activated = subscription.value.copyWith(
        subscriberId: response.subscriberId,
        status: SubscriptionStatus.registered,
        operator: detectOperator(subscription.value.phone),
        lastValidationTime: DateTime.now(),
      );
      subscription.value = activated;
      await _storage.saveSubscription(activated);
      pendingReferenceNo.value = null;
      return response;
    } catch (e) {
      errorMessage.value = _humaniseError(e);
      rethrow;
    } finally {
      isWorking.value = false;
    }
  }

  /// Re-issues an OTP using the most recent phone number.
  Future<void> resendOtp() async {
    final phone = subscription.value.phone;
    if (phone.isEmpty) {
      errorMessage.value = 'Phone number missing. Please register again.';
      return;
    }
    if (resendSecondsRemaining.value > 0) return;
    await sendOtp(phone);
  }

  /// Cancels the subscription with `unsubscribe.php` and clears the
  /// local cache, then redirects the user to the subscription screen.
  Future<void> unsubscribe() async {
    if (!_storage.hasRegisteredPhone()) {
      _navigateTo(AppRoutes.subscription);
      return;
    }
    isWorking.value = true;
    errorMessage.value = null;
    try {
      await _service.unsubscribe(subscription.value.phone);
    } catch (e) {
      // Even if the backend fails we still wipe the local cache and
      // kick the user to the subscription screen.
      developer.log(
        'Unsubscribe failed',
        name: 'SubscriptionController',
        error: e,
      );
      errorMessage.value = _humaniseError(e);
    } finally {
      await _storage.clearSubscription();
      subscription.value = Subscription.empty;
      pendingReferenceNo.value = null;
      isWorking.value = false;
      _navigateTo(AppRoutes.subscription);
    }
  }

  /// Convenience for the Settings refresh button.
  Future<void> refreshFromBackend() async {
    await validateSubscription(silent: false);
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Merges a freshly fetched [SubscriptionStatusResponse] into the
  /// current cached [Subscription] snapshot.
  Subscription _applyStatus(
    Subscription current,
    SubscriptionStatusResponse status,
  ) {
    return current.copyWith(
      subscriberId: status.subscriberId ?? current.subscriberId,
      status: status.isRegistered
          ? SubscriptionStatus.registered
          : SubscriptionStatus.unregistered,
      operator: detectOperator(current.phone),
      lastValidationTime: DateTime.now(),
    );
  }

  void _scheduleBackgroundValidation() {
    _backgroundValidator?.cancel();
    _backgroundValidator = Timer.periodic(
      AppConfig.validationInterval,
      (_) {
        if (_storage.hasRegisteredPhone()) {
          validateSubscription(silent: true);
        }
      },
    );
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    resendSecondsRemaining.value = AppConfig.otpResendCooldown.inSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSecondsRemaining.value <= 0) {
        timer.cancel();
        return;
      }
      resendSecondsRemaining.value -= 1;
    });
  }

  void _navigateTo(String route) {
    if (hasNavigated.value) return;
    hasNavigated.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed(route);
    });
  }

  String _humaniseError(Object error) {
    final raw = error.toString();
    if (raw.contains('SocketException') || raw.contains('NetworkException')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (raw.contains('TimeoutException') || raw.contains('timed out')) {
      return 'Server is taking too long. Please try again.';
    }
    if (raw.contains('BadRequestException')) {
      final colon = raw.indexOf(':');
      return colon >= 0 && colon + 2 < raw.length
          ? raw.substring(colon + 2)
          : raw;
    }
    if (raw.contains('ServerException')) {
      return 'Subscription service is unavailable. Please try again later.';
    }
    return 'Something went wrong. Please try again.';
  }
}