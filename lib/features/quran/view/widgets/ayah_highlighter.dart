import 'package:flutter/material.dart';

import '../../model/ayah_box.dart';


class AyahHighlighter extends CustomPainter {
  final List<AyahBox> boxes;
  final int? selected;
  final double scaleX, scaleY;

  AyahHighlighter(
      this.boxes, this.selected, this.scaleX, this.scaleY);

  @override
  void paint(Canvas c, Size _) {
    if (selected == null) return;
    final paint = Paint()..color = Colors.yellow.withOpacity(0.35);
    for (final b in boxes) {
      if (b.ayahNumber == selected) {
        c.drawRect(
          Rect.fromLTWH(
            b.minX * scaleX,
            b.minY * scaleY,
            b.width * scaleX,
            b.height * scaleY,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant AyahHighlighter old) =>
      old.selected != selected ||
          old.scaleX != scaleX ||
          old.scaleY != scaleY ||
          old.boxes != boxes;
}
