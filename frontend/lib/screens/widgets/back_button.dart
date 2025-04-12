import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBackButton extends StatelessWidget {
  final String? path;
  final Color? color;

  const CustomBackButton({
    super.key,
    this.path,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back,
        color: color ?? Theme.of(context).colorScheme.onPrimary,
      ),
      onPressed: () {
        if (path != null) {
          context.goNamed(path!);
        } else {
          context.pop();
        }
      },
    );
  }
}