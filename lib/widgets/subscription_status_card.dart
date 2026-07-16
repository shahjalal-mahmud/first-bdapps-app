import 'package:flutter/material.dart';

import '../models/subscription_model.dart';

/// Reusable card that summarises the current subscription state.
///
/// Shown on the subscription screen (with the cached phone number) and
/// on the settings screen (with every persisted field).
class SubscriptionStatusCard extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionStatusCard({
    super.key,
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = subscription.status.isRegistered;
    final color = isActive
        ? const Color(0xFF36C26F)
        : const Color(0xFFE0A23A);
    final label = isActive ? 'REGISTERED' : 'UNREGISTERED';
    final icon = isActive
        ? Icons.verified_rounded
        : Icons.warning_amber_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withValues(alpha: 0.7),
          width: 1.4,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'Subscription ${subscription.operator.displayName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Row(label: 'Phone', value: _formatPhone(subscription.phone)),
          if (subscription.subscriberId.isNotEmpty)
            _Row(label: 'Subscriber', value: subscription.subscriberId),
          _Row(
            label: 'Last checked',
            value: _formatDate(subscription.lastValidationTime),
          ),
        ],
      ),
    );
  }

  static String _formatPhone(String phone) {
    if (phone.isEmpty) return '-';
    if (phone.length == 11) {
      return '${phone.substring(0, 4)}-${phone.substring(4, 7)}-${phone.substring(7)}';
    }
    return phone;
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $hh:$mm';
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}