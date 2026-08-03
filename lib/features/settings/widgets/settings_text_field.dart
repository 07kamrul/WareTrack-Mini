import 'package:flutter/material.dart';

class SettingsTextField extends StatelessWidget {
  const SettingsTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
    this.keyboardType,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: false,
      keyboardType: keyboardType,
      minLines: 1,
      decoration: InputDecoration(labelText: label, errorText: errorText),
      onChanged: onChanged,
    );
  }
}
