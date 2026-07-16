import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription_model.dart';

/// Persists the four fields the PHP backend cares about:
///
///   * phone
///   * subscriberId
///   * subscriptionStatus
///   * lastValidationTime
///
/// No Firebase, no Firestore, no Google Sign-In. Plain
/// [SharedPreferences] only.
///
/// The local cache is **never** trusted on its own - the app always
/// verifies with the backend before granting access to protected
/// screens (see [SubscriptionController]).
class LocalStorageService {
  static const _kPhone = 'bdapps.phone';
  static const _kSubscriberId = 'bdapps.subscriber_id';
  static const _kStatus = 'bdapps.subscription_status';
  static const _kLastValidation = 'bdapps.last_validation_time';

  final SharedPreferences _prefs;
  LocalStorageService(this._prefs);

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  /// True when a phone number has ever been registered on this device.
  bool hasRegisteredPhone() {
    final phone = _prefs.getString(_kPhone);
    return phone != null && phone.isNotEmpty;
  }

  /// Returns the cached [Subscription] snapshot or [Subscription.empty].
  Subscription readSubscription() {
    final phone = _prefs.getString(_kPhone) ?? '';
    if (phone.isEmpty) return Subscription.empty;
    return Subscription.fromMap({
      'phone': phone,
      'subscriberId': _prefs.getString(_kSubscriberId) ?? '',
      'status': _prefs.getString(_kStatus) ?? 'UNKNOWN',
      'operator': detectOperator(phone).id,
      'lastValidationTime': _prefs.getString(_kLastValidation),
    });
  }

  /// Persists the supplied [Subscription] snapshot.
  Future<void> saveSubscription(Subscription subscription) async {
    await _prefs.setString(_kPhone, subscription.phone);
    if (subscription.subscriberId.isNotEmpty) {
      await _prefs.setString(_kSubscriberId, subscription.subscriberId);
    }
    await _prefs.setString(_kStatus, subscription.status.id);
    await _prefs.setString(
      _kLastValidation,
      subscription.lastValidationTime.toIso8601String(),
    );
  }

  /// Wipes every cached subscription key. Called after a successful
  /// unsubscribe, when the backend reports the subscription is no
  /// longer REGISTERED, or when we need to force a fresh flow.
  Future<void> clearSubscription() async {
    await _prefs.remove(_kPhone);
    await _prefs.remove(_kSubscriberId);
    await _prefs.remove(_kStatus);
    await _prefs.remove(_kLastValidation);
  }
}