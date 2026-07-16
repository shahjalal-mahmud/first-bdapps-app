import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/subscription_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/app_background.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/otp_input.dart';

/// OTP verification step. Triggered after a successful subscription
/// registration. Submits to the backend; on success the user is sent
/// to Home.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _otp = '';
  final SubscriptionController _controller = Get.find();

  @override
  void initState() {
    super.initState();
    // Auto-focus the first cell once the screen finishes its first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  Future<void> _submit() async {
    if (_otp.length != 6) {
      _showError('Please enter the 6-digit OTP sent to your phone.');
      return;
    }
    try {
      final response = await _controller.verifyOtp(_otp);
      if (!mounted) return;
      if (response.isRegistered) {
        Get.offAllNamed(AppRoutes.home);
      } else {
        _showError(
          _controller.errorMessage.value ??
              'OTP verification failed. Please check and try again.',
        );
      }
    } catch (_) {
      _showError(
        _controller.errorMessage.value ??
            'OTP verification failed. Please try again.',
      );
    }
  }

  Future<void> _resend() async {
    await _controller.resendOtp();
    if (!mounted) return;
    final msg = _controller.errorMessage.value;
    if (msg != null) {
      _showError(msg);
    } else {
      Get.snackbar(
        '',
        'A new OTP has been sent to your phone.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF612A7E),
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        titleText: const SizedBox.shrink(),
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
    return Scaffold(
      body: AppBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: cardDecoration(radius: 42),
                child: const Icon(
                  Icons.sms_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Verify OTP',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Obx(
              () => Text(
                'Enter the 6-digit code we sent to ${_controller.subscription.value.phone}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ),
            const SizedBox(height: 32),
            OtpInput(
              onChanged: (value) => setState(() => _otp = value),
              onCompleted: (value) {
                setState(() => _otp = value);
                _submit();
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: Obx(() {
                if (_controller.resendSecondsRemaining.value > 0) {
                  return CountdownTimer(
                    seconds: _controller.resendSecondsRemaining.value,
                  );
                }
                return TextButton(
                  onPressed:
                      _controller.isWorking.value ? null : _resend,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                );
              }),
            ),
            const Spacer(),
            Obx(
              () => _VerifyButton(
                isLoading: _controller.isWorking.value,
                onPressed: _submit,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _VerifyButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF612A7E),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF612A7E),
                ),
              )
            : const Text(
                'VERIFY',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  color: Color(0xFF612A7E),
                ),
              ),
      ),
    );
  }
}