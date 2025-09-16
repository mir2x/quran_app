import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran_app/core/utils/bengali_digit_extension.dart';
import 'package:quran_app/features/sura/model/ayah.dart';
import 'package:quran_app/features/sura/view/widgets/ayah_action_bottom_sheet.dart';
import 'package:quran_app/features/sura/viewmodel/font_settings_viewmodel.dart';
import 'package:quran_app/features/sura/viewmodel/sura_viewmodel.dart';

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
    final borderColor =
    isHighlighted ? Theme.of(context).primaryColor : Colors.transparent;
    final cardElevation = isHighlighted ? 4.0 : 0.5;

    // PERFORMANCE: Prevents repainting this card when other cards are highlighted.
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () =>
            showAyahActionBottomSheet(context, suraNumber, ayah, suraName, ref),
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
                  letterSpacing: 0,
                ),
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
                textAlign: TextAlign.center,
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
        height: 1.8,
        color: Colors.black87,
        letterSpacing: 0,
      ),
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

    // PERFORMANCE: Use a Column with .map() instead of a nested ListView.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 30, thickness: 0.5, color: Colors.grey),
        ...translationsToShow.map((translation) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translation.translatorName,
                  style: const TextStyle(
                    fontFamily: 'SolaimanLipi',
                    color: Colors.grey,
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
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
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