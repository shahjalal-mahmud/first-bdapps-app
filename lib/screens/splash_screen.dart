import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/subscription_controller.dart';
import '../widgets/app_background.dart';

/// Shown briefly on app start. Delegates navigation decisions to
/// [SubscriptionController.bootstrap] which inspects the local cache
/// and (when a phone is registered) verifies the subscription with the
/// backend.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<SubscriptionController>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'QUIZ',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'আমার প্রশ্ন',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}