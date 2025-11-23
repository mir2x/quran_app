import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:quran_app/core/utils/bengali_digit_extension.dart';
import '../../../../core/utils/sura_page_router.dart';
import '../../../sura/viewmodel/sura_viewmodel.dart';
import '../../model/sura_list_item.dart';

class SuraListItem extends ConsumerWidget {
  final SuraListItemModel sura;

  const SuraListItem({super.key, required this.sura});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        Future.delayed(Duration.zero, () {
          if (!context.mounted) return;

          final targetSura = sura.number;
          final int? targetIndex = null;

          final activeSurahs = ref.read(activeSurahPagesProvider);
          final bool routeExists = activeSurahs.contains(targetSura);

          if (routeExists) {
            debugPrint("Surah $targetSura page exists. Popping back to it.");
            Navigator.popUntil(context,
                (route) => route.settings.name == '/surah/$targetSura');
          } else {
            debugPrint(
                "Surah $targetSura page does not exist. Pushing new page.");
            Navigator.push(
                context, createSurahPageRoute(targetSura, targetIndex));
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            _buildSuraNumber(),
            const SizedBox(width: 16.0),
            _buildSuraNames(),
            const Spacer(),
            _buildRevelationInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuraNumber() {
    return Container(
      width: 45,
      height: 45,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        sura.number.toBengaliDigit(),
        style: TextStyle(
          fontFamily: 'SolaimanLipi',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.green.shade700,
        ),
      ),
    );
  }

  Widget _buildSuraNames() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sura.nameBangla,
          style: const TextStyle(
            fontFamily: 'SolaimanLipi',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sura.meaningBangla,
          style: TextStyle(
            fontFamily: 'SolaimanLipi',
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildRevelationInfo() {
    List<List<dynamic>> iconData = sura.revelationType == RevelationType.Makki
        ? HugeIcons.strokeRoundedKaaba01
        : HugeIcons.strokeRoundedMosque04;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HugeIcon(icon: iconData, color: Colors.grey.shade400, size: 28),
        HugeIcon(icon: iconData, color: Colors.grey.shade400, size: 28),
        const SizedBox(width: 8.0),
        Text(
          sura.nameArabic,
          style: GoogleFonts.amiri(
            fontSize: 18,
            color: Colors.green.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
