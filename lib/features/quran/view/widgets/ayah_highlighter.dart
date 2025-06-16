import 'package:flutter/material.dart';

import '../../model/ayah_box.dart';


// Inside AyahHighlighter class (or its definition)
class AyahHighlighter extends CustomPainter {
  final List<AyahBox> boxes;
  // Add suraNumber if needed by paint logic, otherwise remove
  final int? selectedSuraNumber;
  final int? selectedAyahNumber;
  final double scaleX;
  final double scaleY;

  AyahHighlighter(this.boxes, this.selectedSuraNumber, this.selectedAyahNumber, this.scaleX, this.scaleY); // Update constructor


  @override
  void paint(Canvas canvas, Size size) {
    if (selectedAyahNumber == null) return;

    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.6) // Adjust color and opacity as needed
      ..style = PaintingStyle.fill;

    // Find all boxes on the current page for the selected sura and ayah
    // Use the selectedSuraNumber and selectedAyahNumber passed to the painter
    final boxesToHighlight = boxes.where(
            (box) =>
        box.suraNumber == selectedSuraNumber &&
            box.ayahNumber == selectedAyahNumber);


    for (final box in boxesToHighlight) {
      final rect = Rect.fromLTWH(
        box.minX * scaleX,
        box.minY * scaleY,
        box.width * scaleX,
        box.height * scaleY,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AyahHighlighter oldDelegate) {
    // Only repaint if the selected sura/ayah changes or the scaling changes
    return oldDelegate.selectedSuraNumber != selectedSuraNumber ||
        oldDelegate.selectedAyahNumber != selectedAyahNumber ||
        oldDelegate.scaleX != scaleX ||
        oldDelegate.scaleY != scaleY ||
        oldDelegate.boxes != boxes; // Also repaint if the box list changes (e.g., page change)
  }
}
