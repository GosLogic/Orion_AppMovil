import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orion_app/core/theme/orion_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final TextInputAction textInputAction;
  final VoidCallback? onEditingComplete;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.inputFormatters,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.onEditingComplete,
  });

  static const Color _fieldFill = Color(0xFFFAFBFC);
  static const Color _borderColor = Color(0xFFE0E4E8);
  static const Color _focusedBorder = OrionColors.primary;
  static const Color _labelColor = OrionColors.textPrimary;
  static const Color _errorColor = OrionColors.error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _labelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: inputFormatters,
          enabled: enabled,
          textInputAction: textInputAction,
          onEditingComplete: onEditingComplete,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _labelColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _labelColor.withValues(alpha: 0.45),
              fontSize: 16,
            ),
            filled: true,
            fillColor: enabled ? _fieldFill : _fieldFill.withValues(alpha: 0.6),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: _focusedBorder, size: 26)
                : null,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _borderColor, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _focusedBorder, width: 2.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _errorColor, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _errorColor, width: 2),
            ),
            errorStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _errorColor,
            ),
          ),
        ),
      ],
    );
  }
}
