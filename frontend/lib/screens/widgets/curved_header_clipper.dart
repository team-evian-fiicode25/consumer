
import 'package:flutter/cupertino.dart';

class CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height * 0.3);

    path.cubicTo(
      size.width * 0.1, size.height * 0.45,
      size.width * 0.25, size.height * 0.6,
      size.width * 0.5, size.height * 0.4,
    );

    path.cubicTo(
      size.width * 0.75, size.height * 0.2,
      size.width * 0.85, size.height * 0.55,
      size.width, size.height * 0.3,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
