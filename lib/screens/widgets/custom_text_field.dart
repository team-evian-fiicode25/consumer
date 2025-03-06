import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onToggleVisibility;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onToggleVisibility,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? !isPasswordVisible : false,
      decoration: InputDecoration(
        filled: false,
        labelText: label,
        border: UnderlineInputBorder(),
        focusedBorder: UnderlineInputBorder(),
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
              icon: Icon(isPasswordVisible ? Icons.visibility_off : Icons.visibility),
              onPressed: onToggleVisibility,
            )
            : null,
      ),
      validator: validator,
    );
  }
}
