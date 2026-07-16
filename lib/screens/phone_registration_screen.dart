import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/subscription_controller.dart';
import '../models/subscription_model.dart';
import '../routes/app_routes.dart';
import '../widgets/app_background.dart';

/// First step of the subscription flow. The user enters their
/// Robi or Airtel Bangladesh mobile number, which we save locally and
/// then pass to the subscription screen.
class PhoneRegistrationScreen extends StatefulWidget {
  const PhoneRegistrationScreen({super.key});

  @override
  State<PhoneRegistrationScreen> createState() =>
      _PhoneRegistrationScreenState();
}

class _PhoneRegistrationScreenState extends State<PhoneRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final SubscriptionController _subscription = Get.find();
  Operator _operator = Operator.robi;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _normalisePhone(_phoneController.text, _operator);
    if (!_isValidPhone(phone, _operator)) {
      _showError(
        'Please enter a valid ${_operator.displayName} Bangladesh mobile number.',
      );
      return;
    }
    // Send the OTP first; only after the backend hands back a
    // referenceNo do we move to the OTP screen. This matches the
    // production PHP backend where send_otp.php is the entry point.
    try {
      final response = await _subscription.sendOtp(phone);
      if (response.success &&
          response.referenceNo != null &&
          response.referenceNo!.isNotEmpty) {
        if (!mounted) return;
        Get.offAllNamed(AppRoutes.otp);
        return;
      }
      _showError(
        response.message ??
            'Could not start subscription. Please try again.',
      );
    } catch (_) {
      _showError(
        _subscription.errorMessage.value ??
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

  /// Normalises "8801XXXXXXXXX", "01XXXXXXXXX", or "1XXXXXXXXX" to "01XXXXXXXXX".
  static String _normalisePhone(String input, Operator operator) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    String normalised = digits;
    if (digits.startsWith('880') && digits.length == 13) {
      normalised = '0${digits.substring(3)}';
    } else if (digits.startsWith('88') && digits.length == 12) {
      normalised = '0${digits.substring(2)}';
    } else if (digits.startsWith('1') && digits.length == 10) {
      normalised = '0$digits';
    }

    // Force the operator-specific prefix when the user typed something
    // ambiguous, so the backend talks to the correct carrier.
    const prefix = {Operator.robi: '018', Operator.airtel: '016'};
    if (operator != Operator.unknown && normalised.length >= 4) {
      final want = prefix[operator]!;
      if (!normalised.startsWith(want)) {
        // Only override when the user-typed prefix matches the other
        // operator - otherwise keep what they typed.
        final other = operator == Operator.robi ? '016' : '018';
        if (normalised.startsWith(other)) {
          normalised = want + normalised.substring(3);
        }
      }
    }
    return normalised;
  }

  static bool _isValidPhone(String phone, Operator operator) {
    if (!RegExp(r'^01[3-9][0-9]{8}$').hasMatch(phone)) return false;
    if (operator == Operator.robi && !phone.startsWith('018')) return false;
    if (operator == Operator.airtel && !phone.startsWith('016')) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: cardDecoration(radius: 42),
                  child: const Icon(
                    Icons.phone_android_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter Your Number',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'We use this number to verify your BDApps subscription.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 28),
              _OperatorSelector(
                value: _operator,
                onChanged: (op) => setState(() => _operator = op),
              ),
              const SizedBox(height: 18),
              _PhoneField(
                controller: _phoneController,
                operator: _operator,
              ),
              const SizedBox(height: 24),
              Obx(
                () => _ContinueButton(
                  isLoading:
                      _subscription.isLoading.value ||
                          _subscription.isWorking.value,
                  onPressed: _submit,
                ),
              ),
              const Spacer(),
              Center(
                child: Text(
                  'Supported operators: Robi (018), Airtel (016)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperatorSelector extends StatelessWidget {
  final Operator value;
  final ValueChanged<Operator> onChanged;

  const _OperatorSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _OperatorChip(
            label: 'Robi',
            selected: value == Operator.robi,
            onTap: () => onChanged(Operator.robi),
          ),
          _OperatorChip(
            label: 'Airtel',
            selected: value == Operator.airtel,
            onTap: () => onChanged(Operator.airtel),
          ),
        ],
      ),
    );
  }
}

class _OperatorChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OperatorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected
                  ? const Color(0xFF612A7E)
                  : Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final Operator operator;

  const _PhoneField({required this.controller, required this.operator});

  @override
  Widget build(BuildContext context) {
    final prefix = operator == Operator.robi ? '+880 18' : '+880 16';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Text(
              prefix,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.4)),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.phone,
              maxLength: 8,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 2,
              ),
              cursorColor: Colors.white,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                hintText: 'XXXXXXXX',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 2,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 18,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required.';
                }
                if (value.length != 8) {
                  return 'Phone number must be 8 digits after ${prefix.substring(prefix.length - 3)}.';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _ContinueButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF612A7E),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                'CONTINUE',
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