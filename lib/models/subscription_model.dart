/// Domain model representing a user's BDApps subscription state.
///
/// The PHP backend only exposes a few canonical fields per user, so the
/// locally cached state is intentionally minimal:
///
///   * phone                 - Bangladesh mobile number (01XXXXXXXXX).
///   * subscriberId          - BDApps identifier (tel:88XXXXXXXXXX).
///   * subscriptionStatus    - REGISTERED / UNREGISTERED / UNKNOWN.
///   * lastValidationTime    - last successful `check_subscription.php`.
///   * operator              - derived (Robi/Airtel) from the phone prefix.
library;

/// Mobile network operators supported by the application.
enum Operator { robi, airtel, unknown }

extension OperatorX on Operator {
  String get displayName {
    switch (this) {
      case Operator.robi:
        return 'Robi';
      case Operator.airtel:
        return 'Airtel';
      case Operator.unknown:
        return 'Unknown';
    }
  }

  String get id {
    switch (this) {
      case Operator.robi:
        return 'robi';
      case Operator.airtel:
        return 'airtel';
      case Operator.unknown:
        return 'unknown';
    }
  }
}

Operator operatorFromId(String? value) {
  switch (value) {
    case 'robi':
      return Operator.robi;
    case 'airtel':
      return Operator.airtel;
    default:
      return Operator.unknown;
  }
}

/// Subscribed / unsubscribed / unknown.
enum SubscriptionStatus { registered, unregistered, unknown }

extension SubscriptionStatusX on SubscriptionStatus {
  String get id {
    switch (this) {
      case SubscriptionStatus.registered:
        return 'REGISTERED';
      case SubscriptionStatus.unregistered:
        return 'UNREGISTERED';
      case SubscriptionStatus.unknown:
        return 'UNKNOWN';
    }
  }

  bool get isRegistered => this == SubscriptionStatus.registered;
}

SubscriptionStatus subscriptionStatusFromId(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'REGISTERED':
      return SubscriptionStatus.registered;
    case 'UNREGISTERED':
      return SubscriptionStatus.unregistered;
    default:
      return SubscriptionStatus.unknown;
  }
}

/// Heuristic operator detection based on Bangladesh MSISDN prefixes.
Operator detectOperator(String phone) {
  if (phone.startsWith('018')) return Operator.robi;
  if (phone.startsWith('016')) return Operator.airtel;
  return Operator.unknown;
}

/// Immutable snapshot of a BDApps subscription.
class Subscription {
  final String phone;
  final String subscriberId;
  final SubscriptionStatus status;
  final Operator operator;
  final DateTime lastValidationTime;

  const Subscription({
    required this.phone,
    required this.subscriberId,
    required this.status,
    required this.operator,
    required this.lastValidationTime,
  });

  /// Sentinel epoch used when we don't yet have a real timestamp.
  static final DateTime _epochStart =
      DateTime.fromMillisecondsSinceEpoch(0);

  /// Convenience for "no subscription" UI states.
  static final Subscription empty = Subscription(
    phone: '',
    subscriberId: '',
    status: SubscriptionStatus.unknown,
    operator: Operator.unknown,
    lastValidationTime: _epochStart,
  );

  Subscription copyWith({
    String? phone,
    String? subscriberId,
    SubscriptionStatus? status,
    Operator? operator,
    DateTime? lastValidationTime,
  }) {
    return Subscription(
      phone: phone ?? this.phone,
      subscriberId: subscriberId ?? this.subscriberId,
      status: status ?? this.status,
      operator: operator ?? this.operator,
      lastValidationTime: lastValidationTime ?? this.lastValidationTime,
    );
  }

  Map<String, dynamic> toMap() => {
    'phone': phone,
    'subscriberId': subscriberId,
    'status': status.id,
    'operator': operator.id,
    'lastValidationTime': lastValidationTime.toIso8601String(),
  };

  factory Subscription.fromMap(Map<String, dynamic> map) {
    final phone = (map['phone'] as String?) ?? '';
    return Subscription(
      phone: phone,
      subscriberId: (map['subscriberId'] as String?) ?? '',
      status: subscriptionStatusFromId(map['status'] as String?),
      operator: operatorFromId(map['operator'] as String?),
      lastValidationTime: DateTime.tryParse(
            (map['lastValidationTime'] as String?) ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}