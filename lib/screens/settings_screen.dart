import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/subscription_controller.dart';
import '../models/subscription_model.dart';
import '../widgets/app_background.dart';
import '../widgets/subscription_status_card.dart';

/// Settings screen. Includes a Subscription section with:
///   * All persisted fields.
///   * Refresh button (re-validates with the backend).
///   * Unsubscribe button (clears local data + backend call).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _refresh(SubscriptionController controller) async {
    await controller.refreshFromBackend();
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        '',
        controller.subscription.value.status.isRegistered
            ? 'Subscription is active.'
            : 'Subscription is currently inactive.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF612A7E),
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        titleText: const SizedBox.shrink(),
      );
    }
  }

  Future<void> _unsubscribe(SubscriptionController controller) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Unsubscribe?'),
        content: const Text(
          'You will lose access to the app until you subscribe again. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB23B3B)),
            child: const Text('Unsubscribe'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await controller.unsubscribe();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubscriptionController>();
    return Scaffold(
      body: AppBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionTitle(title: 'Subscription'),
                    Obx(
                      () => SubscriptionStatusCard(
                        subscription: controller.subscription.value,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Refresh',
                              icon: Icons.refresh_rounded,
                              isLoading: controller.isLoading.value,
                              onPressed: () => _refresh(controller),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              label: 'Unsubscribe',
                              icon: Icons.cancel_outlined,
                              background: const Color(0xFFB23B3B),
                              foreground: Colors.white,
                              isLoading: controller.isWorking.value,
                              enabled: controller
                                      .subscription.value.status !=
                                  SubscriptionStatus.unknown,
                              onPressed: () => _unsubscribe(controller),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const _SectionTitle(title: 'About'),
                    const _AboutTile(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool enabled;
  final Color? background;
  final Color? foreground;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final bg = background ?? Colors.white;
    final fg = foreground ?? const Color(0xFF612A7E);
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: (isLoading || !enabled) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.45),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        icon: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              )
            : Icon(icon, color: fg, size: 18),
        label: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(radius: 20),
      padding: const EdgeInsets.all(16),
      child: const Row(
        children: [
          Icon(Icons.psychology_rounded, color: Colors.white, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amar Proshno',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Quiz + AI study companion.\nVersion 1.0.0',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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