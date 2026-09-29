import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Rounded text field shared by the login and signup forms. Password fields
/// get a show / hide toggle.
class AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _obscure = true;

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    const errorColor = Color(0xFFD64545);

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      cursorColor: p.primary,
      style: TextStyle(color: p.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: p.textSecondary),
        filled: true,
        fillColor: p.card,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        prefixIcon: Icon(widget.icon, color: p.textSecondary),
        suffixIcon: widget.isPassword
            ? IconButton(
          icon: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: p.textSecondary,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        )
            : null,
        border: _border(p.border),
        enabledBorder: _border(p.border),
        focusedBorder: _border(p.primary, width: 1.5),
        errorBorder: _border(errorColor),
        focusedErrorBorder: _border(errorColor, width: 1.5),
      ),
    );
  }
}

/// Full-width pill button that swaps its label for a spinner while loading.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.primary,
          disabledForegroundColor: p.onPrimary,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? SizedBox(
            key: const ValueKey('loading'),
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: p.onPrimary,
            ),
          )
              : Text(
            label,
            key: const ValueKey('label'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}