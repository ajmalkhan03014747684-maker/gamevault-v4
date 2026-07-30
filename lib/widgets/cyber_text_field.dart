import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Dark glass-style text input used on Login/Register, Withdraw, etc.
class CyberTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType keyboardType;

  const CyberTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: AppText.body(size: 15, color: AppColors.text),
        cursorColor: AppColors.primaryPurple,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppText.body(size: 15, color: AppColors.muted),
          prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }
}
