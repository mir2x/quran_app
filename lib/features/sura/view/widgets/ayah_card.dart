import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_app/core/utils/bengali_digit_extension.dart';
import '../../model/ayah.dart';
import '../../model/word_by_word.dart';
import '../../viewmodel/sura_viewmodel.dart';
import 'ayah_action_bottom_sheet.dart';

class AyahCard extends ConsumerWidget {
  final Ayah ayah;
  final String suraName;
  final bool isHighlighted; // This flag controls the audio highlight

  const AyahCard({
    super.key,
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
      onTap: () => showAyahActionBottomSheet(context, ayah, suraName),
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
                _buildWordByWordView(ayah.words)
              else
                _buildArabicText(),
              if (showTranslations &&
                  selectedTranslators.isNotEmpty &&
                  !showWords)
                _buildTranslations(selectedTranslators),
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

  Widget _buildWordByWordView(List<WordByWord> words) {
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
                style: GoogleFonts.amiri(
                  fontSize: 28.sp,
                  color: Colors.black87,
                  height: 1.2.h,
                ),
              ),
              SizedBox(height: 4.0.h),
              Text(
                word.bengali,
                style: const TextStyle(
                  fontFamily: 'SolaimanLipi',
                  fontSize: 15,
                  color: Colors.green,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildArabicText() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        ayah.arabicText,
        style: GoogleFonts.amiri(
          fontSize: 28,
          height: 1.5,
          color: Colors.black87,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildTranslations(List<String> selectedTranslators) {
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
                    fontFamily: 'SolaimanLipi',
                    fontSize: 16,
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
