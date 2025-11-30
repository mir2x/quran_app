import 'package:flutter/material.dart';

class AdaptiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const AdaptiveText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return Text(text, style: style);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final lineCount = textPainter.computeLineMetrics().length;

        if (lineCount <= 1) {
          return Text(text, style: style, textAlign: TextAlign.center);
        }

        final lastLineRange = textPainter.getLineBoundary(
          TextPosition(offset: text.length - 1),
        );

        final mainBody = text.substring(0, lastLineRange.start);
        final lastLine = text.substring(lastLineRange.start);

        return RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            style: style,
            children: [
              TextSpan(text: mainBody),
              WidgetSpan(
                child: Container(
                  width: double.infinity,
                  child: Text(
                    lastLine,
                    style: style,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
