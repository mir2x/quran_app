import 'package:flutter/material.dart';

class AyahHighlighter extends CustomPainter {
  final List<Rect> highlightRects;

  AyahHighlighter(this.highlightRects);

  @override
  void paint(Canvas canvas, Size size) {
    if (highlightRects.isEmpty) return;

    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (final rect in highlightRects) {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AyahHighlighter oldDelegate) {
    return oldDelegate.highlightRects != highlightRects;
  }
}
