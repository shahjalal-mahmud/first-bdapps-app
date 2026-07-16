import 'package:flutter_test/flutter_test.dart';

import 'package:amar_proshno/models/subscription_model.dart';

void main() {
  group('Subscription model', () {
    test('isRegistered reflects REGISTERED/UNREGISTERED', () {
      final registered = Subscription(
        phone: '01812345678',
        subscriberId: 'tel:8801812345678',
        operator: Operator.robi,
        status: SubscriptionStatus.registered,
        lastValidationTime: DateTime.now(),
      );
      expect(registered.status.isRegistered, isTrue);

      final unregistered = Subscription(
        phone: '01812345678',
        subscriberId: 'tel:8801812345678',
        operator: Operator.robi,
        status: SubscriptionStatus.unregistered,
        lastValidationTime: DateTime.now(),
      );
      expect(unregistered.status.isRegistered, isFalse);

      final unknown = Subscription(
        phone: '',
        subscriberId: '',
        operator: Operator.unknown,
        status: SubscriptionStatus.unknown,
        lastValidationTime: DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(unknown.status.isRegistered, isFalse);
      expect(unknown.phone, isEmpty);
    });

    test('round-trips through toMap/fromMap', () {
      final original = Subscription(
        phone: '01612345678',
        subscriberId: 'tel:8801612345678',
        operator: Operator.airtel,
        status: SubscriptionStatus.registered,
        lastValidationTime: DateTime.utc(2025, 1, 5, 12),
      );
      final restored = Subscription.fromMap(original.toMap());
      expect(restored.phone, original.phone);
      expect(restored.subscriberId, original.subscriberId);
      expect(restored.operator, original.operator);
      expect(restored.status, original.status);
      expect(
        restored.lastValidationTime.toIso8601String(),
        original.lastValidationTime.toIso8601String(),
      );
    });

    test('operator detection infers Robi / Airtel from prefix', () {
      expect(detectOperator('01812345678'), Operator.robi);
      expect(detectOperator('01612345678'), Operator.airtel);
      expect(detectOperator('01712345678'), Operator.unknown);
    });
  });
}