import 'dart:async';

import 'package:flutter/material.dart';

/// Compact countdown used by the OTP screen. Displays `MM:SS` until
/// [seconds] reaches zero, then flips to [expiredLabel].
class CountdownTimer extends StatefulWidget {
  final int seconds;
  final TextStyle? textStyle;
  final String expiredLabel;

  const CountdownTimer({
    super.key,
    required this.seconds,
    this.textStyle,
    this.expiredLabel = 'You can resend the OTP now.',
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    if (_remaining > 0) _startTimer();
  }

  @override
  void didUpdateWidget(covariant CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seconds != oldWidget.seconds) {
      _remaining = widget.seconds;
      _timer?.cancel();
      if (_remaining > 0) _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remaining -= 1;
        if (_remaining <= 0) {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining <= 0) {
      return Text(
        widget.expiredLabel,
        style: widget.textStyle?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ) ??
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      );
    }
    final minutes = (_remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remaining % 60).toString().padLeft(2, '0');
    return Text(
      'Resend available in $minutes:$seconds',
      style: widget.textStyle?.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
          ) ??
          TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
    );
  }
}