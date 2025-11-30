import 'package:flutter/material.dart';
import 'package:quran_app/core/utils/arabic_digit_extension.dart';
import 'package:quran_app/core/utils/bengali_digit_extension.dart';
import '../../model/tilawat_models.dart';

class QuranPageWidget extends StatelessWidget {
  final QuranPage page;

  const QuranPageWidget({super.key, required this.page});

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
        spans.add(
          TextSpan(
            text: '${ayah.text} ',
            style: const TextStyle(
              fontFamily: 'Al Qalam Quran Majeed',
              fontSize: 28,
              height: 2.2,
              color: Color(0xFF2D2D2D),
              letterSpacing: 0,
            ),
          ),
        );
        spans.add(
          TextSpan(
            text: '\u{FD3F}${ayah.ayahNumber.toArabicDigit()}\u{FD3E} ',
            style: const TextStyle(
              fontFamily: 'Al Qalam Quran Majeed',
              fontSize: 28,
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
              letterSpacing: 0,
              height: 2.2,
            ),
          ),
        );
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFDFBF7),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: const Color(0xff344955),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'পারা-${page.paraNumber.toBengaliDigit()}',
                    style: const TextStyle(
                        fontFamily: 'SolaimanLipi',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text(
                    'পৃষ্ঠা-${page.pageNumberInSurah.toBengaliDigit()}',
                    style: const TextStyle(
                        fontFamily: 'SolaimanLipi',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _buildSurahHeader(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative background/border
          Container(
            height: 60,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/image/sura_header_bg.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                    color: const Color(0xFFD4AF37).withOpacity(0.5), width: 2),
              ),
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFFD4AF37).withOpacity(0.1),
                  Colors.transparent
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFBF7),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'Al Qalam Quran Majeed',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 0,
                color: Color(0xFF2D2D2D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBismillah() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 24.0),
        child: Text(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
          style: TextStyle(
            fontFamily: 'Al Qalam Quran Majeed',
            fontSize: 32,
            letterSpacing: 0,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ),
    );
  }
}
