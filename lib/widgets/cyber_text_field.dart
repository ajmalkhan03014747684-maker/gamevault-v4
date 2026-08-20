import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Dark glass-style text input used on Login/Register, Withdraw, etc.
///
/// When obscureText is true (i.e. this is a password field), an eye
/// icon appears letting the user toggle show/hide â€” self-contained,
/// so every existing password field in the app gets this for free.
class CyberTextField extends StatefulWidget {
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
  State<CyberTextField> createState() => _CyberTextFieldState();
}

class _CyberTextFieldState extends State<CyberTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: _obscured,
        keyboardType: widget.keyboardType,
        style: AppText.body(size: 15, color: AppColors.text),
        cursorColor: AppColors.primaryPurple,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AppText.body(size: 15, color: AppColors.muted),
          prefixIcon: Icon(widget.icon, color: AppColors.muted, size: 20),
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _obscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppColors.muted,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscured = !_obscured),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }
}
