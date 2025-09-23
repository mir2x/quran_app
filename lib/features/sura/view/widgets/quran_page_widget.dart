import 'package:flutter/material.dart';
import 'package:quran_app/core/utils/arabic_digit_extension.dart';
import 'package:quran_app/core/utils/bengali_digit_extension.dart';
import '../../model/tilawat_models.dart';

class QuranPageWidget extends StatelessWidget {
  final QuranPage page;

  const QuranPageWidget({super.key, required this.page});

  /// Builds a single list of InlineSpan objects for continuous text flow.
  List<InlineSpan> _buildPageTextSpans() {
    final List<InlineSpan> spans = [];

    for (var contentItem in page.content) {
      if (contentItem.ayahs.first.ayahNumber == 1) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _buildSurahHeader(contentItem.suraNameArabic),
        ));
        if (contentItem.suraNumber != 1 && contentItem.suraNumber != 9) {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _buildBismillah(),
          ));
        }
      }

      for (var ayah in contentItem.ayahs) {
        spans.add(TextSpan(
          text: '${ayah.text} ',
          style: const TextStyle(
            fontFamily: 'KFGQPC Uthmanic Script HAFS',
            fontSize: 24,
            height: 2.2,
            color: Colors.black87,
          ),
        ));
        spans.add(TextSpan(
          text: '\u{FD3F}${ayah.ayahNumber.toArabicDigit()}\u{FD3E} ',
          style: TextStyle(
            fontFamily: 'KFGQPC Uthmanic Script HAFS',
            fontSize: 22,
            color: Colors.teal.shade700,
            fontWeight: FontWeight.bold,
          ),
        ));
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      // The Column will now determine its own height based on its children.
      child: Column(
        // FIX: Set mainAxisSize to min so the Column doesn't try to expand infinitely.
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header (Para and Page number)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            decoration: BoxDecoration(
              color: const Color(0xff344955),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'পারা-${page.paraNumber.toBengaliDigit()}',
                  style: const TextStyle(
                      fontFamily: 'SolaimanLipi', fontSize: 16, color: Colors.white),
                ),
                Text(
                  'পৃষ্ঠা-${page.pageNumberInSurah.toBengaliDigit()}',
                  style: const TextStyle(fontFamily: 'SolaimanLipi', fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Main Content Area - REMOVED Expanded and SingleChildScrollView
          // The RichText widget will now be a direct child of the Column.
          RichText(
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: _buildPageTextSpans(),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets (No Changes Needed) ---
  Widget _buildSurahHeader(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: const BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(color: Color(0xff344955), width: 1.5),
          ),
        ),
        child: Center(
          child: Text(
            name,
            style: const TextStyle(
              fontFamily: 'KFGQPC Uthmanic Script HAFS',
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBismillah() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 16.0),
        child: Text(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
          style: TextStyle(
            fontFamily: 'KFGQPC Uthmanic Script HAFS',
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}