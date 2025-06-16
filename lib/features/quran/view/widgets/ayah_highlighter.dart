import 'package:flutter/material.dart';

import '../../model/ayah_box.dart';


// Inside AyahHighlighter class (or its definition)
class AyahHighlighter extends CustomPainter {
  final List<Rect> highlightRects;

  AyahHighlighter(this.highlightRects); // Update constructor


  @override
  void paint(Canvas canvas, Size size) {
    if (highlightRects.isEmpty) return;

    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.6) // Adjust color and opacity as needed
      ..style = PaintingStyle.fill;

    // Find all boxes on the current page for the selected sura and ayah
    // Use the selectedSuraNumber and selectedAyahNumber passed to the painter
    for (final rect in highlightRects) {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AyahHighlighter oldDelegate) {
    // Only repaint if the selected sura/ayah changes or the scaling changes
    return oldDelegate.highlightRects != highlightRects;
  }
}
