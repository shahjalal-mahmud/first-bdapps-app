import 'package:flutter_test/flutter_test.dart';

import 'package:amar_proshno/models/subscription_model.dart';

void main() {
  group('Subscription model', () {
    test('isCurrentlyActive respects status and expiry', () {
      final active = Subscription(
        phone: '01812345678',
        operator: Operator.robi,
        status: SubscriptionStatus.active,
        expiryDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(active.isCurrentlyActive, isTrue);

      final expired = Subscription(
        phone: '01812345678',
        operator: Operator.robi,
        status: SubscriptionStatus.active,
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(expired.isCurrentlyActive, isFalse);

      final inactive = Subscription(
        phone: '01812345678',
        operator: Operator.airtel,
        status: SubscriptionStatus.inactive,
      );
      expect(inactive.isCurrentlyActive, isFalse);
    });

    test('round-trips through toMap/fromMap', () {
      final original = Subscription(
        phone: '01612345678',
        operator: Operator.airtel,
        status: SubscriptionStatus.active,
        subscriptionDate: DateTime.utc(2025, 1, 1, 10),
        expiryDate: DateTime.utc(2025, 1, 31, 10),
        transactionId: 'TX-1',
        lastValidation: DateTime.utc(2025, 1, 5, 12),
      );
      final restored = Subscription.fromMap(original.toMap());
      expect(restored.phone, original.phone);
      expect(restored.operator, original.operator);
      expect(restored.status, original.status);
      expect(restored.transactionId, original.transactionId);
      expect(restored.expiryDate, original.expiryDate);
    });
  });
}