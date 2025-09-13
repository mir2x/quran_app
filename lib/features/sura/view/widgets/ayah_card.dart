import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_app/core/utils/bengali_digit_extension.dart';
import '../../model/ayah.dart';
import '../../model/word_by_word.dart';
import '../../viewmodel/font_settings_viewmodel.dart';
import '../../viewmodel/sura_viewmodel.dart';
import 'ayah_action_bottom_sheet.dart';

class AyahCard extends ConsumerWidget {
  final int suraNumber;
  final Ayah ayah;
  final String suraName;
  final bool isHighlighted;

  const AyahCard({
    super.key,
    required this.suraNumber,
    required this.ayah,
    required this.suraName,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTranslators = ref.watch(selectedTranslatorsProvider);
    final showTranslations = ref.watch(showTranslationsProvider);
    final showWords = ref.watch(showWordByWordProvider);

    final cardColor = isHighlighted
        ? Theme.of(context).primaryColor.withOpacity(0.1)
        : Theme.of(context).cardTheme.color;
    final borderColor = isHighlighted
        ? Theme.of(context).primaryColor
        : Colors.transparent;
    final cardElevation = isHighlighted ? 4.0 : 0.5;

    return GestureDetector(
      onTap: () => showAyahActionBottomSheet(context, suraNumber, ayah, suraName, ref),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: cardElevation,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: borderColor, width: 2.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCardHeader(context),
              const SizedBox(height: 16),
              if (showWords)
                _buildWordByWordView(ayah.words, ref)
              else
                _buildArabicText(ref),
              if (showTranslations &&
                  selectedTranslators.isNotEmpty &&
                  !showWords)
                _buildTranslations(selectedTranslators, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 1.0,
            ),
          ),
          child: Center(
            child: Text(
              ayah.ayah.toBengaliDigit(),
              style: TextStyle(
                fontFamily: 'SolaimanLipi',
                color: Theme.of(context).primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const Row(
          children: [
            _ColorDot(color: Colors.red),
            _ColorDot(color: Colors.orange),
            _ColorDot(color: Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildWordByWordView(List<WordByWord> words, WidgetRef ref) {

    final arabicFont = ref.watch(arabicFontProvider);
    final arabicFontSize = ref.watch(arabicFontSizeProvider);
    final bengaliFont = ref.watch(bengaliFontProvider);
    final bengaliFontSize = ref.watch(bengaliFontSizeProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: WrapAlignment.start,
        runSpacing: 16.0,
        spacing: 12.0,
        children: words.map((word) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                word.arabic,
                style: TextStyle(
                  fontFamily: arabicFont,
                  fontSize: arabicFontSize,
                ),
                // --- THE POLISH ---
                // Ensures perfect right-alignment, even for single words.
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 4.0.h),
              Text(
                word.bengali,
                style: TextStyle(
                  fontFamily: bengaliFont,
                  fontSize: bengaliFontSize,
                  color: Colors.green,
                ),
                // It's good practice to set direction for all text, even LTR.
                textDirection: TextDirection.ltr,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildArabicText(WidgetRef ref) {
    final arabicFont = ref.watch(arabicFontProvider);
    final arabicFontSize = ref.watch(arabicFontSizeProvider);

    return Text(
      ayah.arabicText,
      style: TextStyle(
        fontFamily: arabicFont,
        fontSize: arabicFontSize,
        height: 1.8, // Increased for better readability
        color: Colors.black87,
      ),
      // --- THE FIX ---
      // These two properties work together to ensure perfect RTL rendering.
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
    );
  }


  Widget _buildTranslations(List<String> selectedTranslators, WidgetRef ref) {
    final bengaliFont = ref.watch(bengaliFontProvider);
    final bengaliFontSize = ref.watch(bengaliFontSizeProvider);

    final translationsToShow = ayah.translations
        .where((t) => selectedTranslators.contains(t.translatorName))
        .toList();

    return Column(
      children: [
        const Divider(height: 30, thickness: 0.5, color: Colors.grey),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: translationsToShow.length,
          itemBuilder: (context, index) {
            final translation = translationsToShow[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translation.translatorName,
                  style: TextStyle(
                    fontFamily: 'SolaimanLipi',
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  translation.text,
                  style: TextStyle(
                    fontFamily: bengaliFont,
                    fontSize: bengaliFontSize,
                    height: 1.5,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 12),
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;

  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
