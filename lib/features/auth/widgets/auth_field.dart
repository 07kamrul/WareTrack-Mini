import 'package:flutter/material.dart';

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.controller,
    this.enabled,
    this.errorText,
  });

  final String label;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final bool? enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        errorText: errorText,
        errorStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
