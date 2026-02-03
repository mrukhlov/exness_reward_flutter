import 'package:flutter/material.dart';

/// Styled text field for auth screens (login, register) with label and icon.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.hintText,
    this.keyboardType,
    this.textCapitalization,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextCapitalization? textCapitalization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization:
              textCapitalization ??
              (obscureText
                  ? TextCapitalization.none
                  : TextCapitalization.words),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, size: 20, color: Colors.grey),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            border: _inputBorder(isDark),
            enabledBorder: _inputBorder(isDark),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      ],
    );
  }

  OutlineInputBorder _inputBorder(bool isDark) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
      ),
    );
  }
}
