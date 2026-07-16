import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 6-digit OTP input. Renders individual focusable cells, auto-advances
/// focus as the user types, supports paste from the system clipboard,
/// and exposes the current value through [onChanged] / [onCompleted].
class OtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final bool enabled;

  const OtpInput({
    super.key,
    this.length = 6,
    required this.onChanged,
    this.onCompleted,
    this.enabled = true,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _value => _controllers.map((c) => c.text).join();

  void _emitChange() {
    widget.onChanged(_value);
    if (_value.length == widget.length && !_value.contains(' ')) {
      widget.onCompleted?.call(_value);
    }
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Pasted content - distribute digits across cells.
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < widget.length; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final lastFilled = digits.length.clamp(1, widget.length) - 1;
      if (lastFilled + 1 < widget.length) {
        _focusNodes[lastFilled + 1].requestFocus();
      } else {
        _focusNodes[lastFilled].unfocus();
      }
      setState(() {});
      _emitChange();
      return;
    }

    if (value.isNotEmpty && index + 1 < widget.length) {
      _focusNodes[index + 1].requestFocus();
    }
    _emitChange();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) {
        return SizedBox(
          width: 44,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _focusNodes[i].hasFocus
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.45),
                width: _focusNodes[i].hasFocus ? 1.8 : 1.2,
              ),
            ),
            child: Center(
              child: TextField(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                enabled: widget.enabled,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: widget.length,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                cursorColor: Colors.white,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => _onChanged(i, v),
                onSubmitted: (_) => _emitChange(),
                onEditingComplete: () => _emitChange(),
                onTap: () => _controllers[i].selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _controllers[i].text.length,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}