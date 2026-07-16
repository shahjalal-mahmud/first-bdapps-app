import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/subscription_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/app_background.dart';
import '../widgets/subscription_status_card.dart';

/// Subscription landing page. Shows benefits, terms and a Subscribe
/// Now button. Also serves as the destination when the backend reports
/// the subscription is no longer active.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static const _benefits = <_BenefitItem>[
    _BenefitItem(
      icon: Icons.psychology_rounded,
      title: 'Unlimited Quizzes',
      description: 'Take unlimited quizzes across all categories.',
    ),
    _BenefitItem(
      icon: Icons.smart_toy_rounded,
      title: 'AI Study Assistant',
      description: 'Chat with our AI tutor whenever you need help.',
    ),
    _BenefitItem(
      icon: Icons.workspace_premium_rounded,
      title: 'Premium Content',
      description: 'Access premium questions and detailed explanations.',
    ),
    _BenefitItem(
      icon: Icons.no_encryption_rounded,
      title: 'No Ads',
      description: 'An ad-free experience across the entire app.',
    ),
  ];

  Future<void> _subscribe(SubscriptionController controller) async {
    final phone = controller.subscription.value.phone;
    if (phone.isEmpty) {
      Get.offAllNamed(AppRoutes.phoneRegistration);
      return;
    }
    try {
      final response = await controller.sendOtp(phone);
      if (response.success &&
          response.referenceNo != null &&
          response.referenceNo!.isNotEmpty) {
        Get.toNamed(AppRoutes.otp);
      } else {
        _showError(
          response.message ?? 'Could not start subscription. Please try again.',
        );
      }
    } catch (_) {
      _showError(
        controller.errorMessage.value ??
            'Could not reach the subscription service. Please try again.',
      );
    }
  }

  void _showError(String message) {
    Get.snackbar(
      '',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFB23B3B),
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      titleText: const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubscriptionController>();
    return Scaffold(
      body: AppBackground(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: cardDecoration(radius: 42),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Amar Proshno Premium',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Subscribe to unlock the full quiz experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 18),
              Obx(() {
                final sub = controller.subscription.value;
                if (sub.phone.isEmpty) return const SizedBox.shrink();
                return SubscriptionStatusCard(subscription: sub);
              }),
              const SizedBox(height: 18),
              _BenefitsList(items: _benefits),
              const SizedBox(height: 18),
              _PriceCard(),
              const SizedBox(height: 18),
              _Terms(),
              const SizedBox(height: 24),
              Obx(
                () => _SubscribeButton(
                  isLoading: controller.isWorking.value,
                  onPressed: () => _subscribe(controller),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                final phone = controller.subscription.value.phone;
                if (phone.isEmpty) {
                  return TextButton(
                    onPressed: () =>
                        Get.offAllNamed(AppRoutes.phoneRegistration),
                    child: const Text(
                      'Change phone number',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                return TextButton(
                  onPressed: () =>
                      Get.offAllNamed(AppRoutes.phoneRegistration),
                  child: Text(
                    'Change number (${controller.subscription.value.phone})',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitItem {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _BenefitsList extends StatelessWidget {
  final List<_BenefitItem> items;

  const _BenefitsList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(radius: 28),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(radius: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Subscription',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Auto-renews every 30 days. Cancel anytime.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'BDT 30 / mo',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Terms extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'By subscribing you agree to be charged via your mobile operator '
        '(Robi or Airtel). Subscription auto-renews until cancelled in '
        'Settings. Standard messaging rates may apply.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.5,
          color: Colors.white.withValues(alpha: 0.75),
          height: 1.45,
        ),
      ),
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SubscribeButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF612A7E),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF612A7E),
                ),
              )
            : const Icon(Icons.flash_on_rounded, color: Color(0xFF612A7E)),
        label: Text(
          isLoading ? 'Starting...' : 'SUBSCRIBE NOW',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: Color(0xFF612A7E),
          ),
        ),
      ),
    );
  }
}