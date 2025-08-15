import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:quran/quran.dart' as quran;
import 'package:share_plus/share_plus.dart';
import '../../model/bookmark.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart';
import '../../viewmodel/bookmark_viewmodel.dart';

// The AyahMenu now needs to show the AudioBottomSheet
import '../widgets/audio_bottom_sheet.dart';

class AyahMenu extends ConsumerWidget {
  const AyahMenu({super.key, required this.anchorRect});

  final Rect anchorRect;

  String toBengaliNumber(int number) {
    const bengaliNumbers = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return number.toString().split('').map((char) => bengaliNumbers[int.parse(char)]).join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuWidth = 300.w;
    final menuHeight = 60.h;
    final verticalOffset = 10.h;

    final selectedAyahState = ref.watch(selectedAyahProvider);
    if (selectedAyahState == null) {
      return const SizedBox.shrink();
    }

    final double menuLeft = (1.sw - menuWidth) / 2;
    final double menuTop = math.max(anchorRect.top - menuHeight - verticalOffset, 0.0);

    final selectedSura = selectedAyahState.suraNumber;
    final selectedAyah = selectedAyahState.ayahNumber;
    final currentPage = ref.watch(currentPageProvider) + 1;
    final bookmarkNotifier = ref.read(bookmarkProvider.notifier);
    final isBookmarked = bookmarkNotifier.isAyahBookmarked(selectedSura, selectedAyah);

    return Positioned(
      left: menuLeft,
      top: menuTop,
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(8.r),
        color: const Color(0xFF294B39),
        child: SizedBox(
          height: menuHeight,
          width: menuWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // --- Bookmark Icon Button (Unchanged) ---
              Expanded(
                child: IconButton(
                  icon: Icon(
                    isBookmarked ? HugeIcons.solidStandardStackStar : HugeIcons.strokeStandardStackStar,
                    color: isBookmarked ? Colors.orangeAccent : Colors.white,
                    size: 24.r,
                  ),
                  onPressed: () {
                    // ... (This logic is correct and remains unchanged)
                    if (isBookmarked) {
                      final identifier = 'ayah-$selectedSura-$selectedAyah';
                      bookmarkNotifier.remove(identifier);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('আয়াতটি বুকমার্ক থেকে সরানো হয়েছে', style: TextStyle(fontSize: 14.sp))));
                    } else {
                      final quranInfoService = ref.read(quranInfoServiceProvider);
                      final para = quranInfoService.getParaBySuraAyah(selectedSura, selectedAyah);
                      final bookmark = Bookmark(type: 'ayah', identifier: 'ayah-$selectedSura-$selectedAyah', sura: selectedSura, ayah: selectedAyah, para: para, page: currentPage);
                      bookmarkNotifier.add(bookmark);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('আয়াতটি বুকমার্ক করা হয়েছে', style: TextStyle(fontSize: 14.sp))));
                    }
                    ref.read(selectedAyahProvider.notifier).clear();
                  },
                ),
              ),

              // --- Play Audio Icon Button (NEW LOGIC) ---
              Expanded(
                child: IconButton(
                  icon: Icon(HugeIcons.solidRoundedPlay, color: Colors.white, size: 24.r),
                  onPressed: () {
                    final selectedState = ref.read(selectedAyahProvider);
                    if (selectedState == null) return;

                    // 1. Pre-fill the audio player settings with the selected ayah.
                    ref.read(selectedAudioSuraProvider.notifier).state = selectedState.suraNumber;
                    ref.read(selectedStartAyahProvider.notifier).state = selectedState.ayahNumber;
                    ref.read(selectedEndAyahProvider.notifier).state = selectedState.ayahNumber; // Play only this one ayah

                    // 2. Clear the current selection to hide this AyahMenu.
                    ref.read(selectedAyahProvider.notifier).clear();

                    // 3. Show the main AudioBottomSheet to handle download/playback.
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        // Pass the sura number to the bottom sheet.
                        return AudioBottomSheet(currentSura: selectedState.suraNumber);
                      },
                    );
                  },
                ),
              ),

              // --- Copy Icon Button (Unchanged) ---
              Expanded(
                child: IconButton(
                  icon: Icon(Icons.copy, color: Colors.white, size: 24.r),
                  onPressed: () async {
                    // ... (This logic is correct and remains unchanged)
                    final arabicText = quran.getVerse(selectedSura, selectedAyah);
                    final formattedText = '(সূরা ${toBengaliNumber(selectedSura)}, আয়াত ${toBengaliNumber(selectedAyah)}) $arabicText';
                    await Clipboard.setData(ClipboardData(text: formattedText));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('আয়াতটি কপি করা হয়েছে', style: TextStyle(fontSize: 14.sp))));
                    ref.read(selectedAyahProvider.notifier).clear();
                  },
                ),
              ),

              // --- Share Icon Button (Unchanged) ---
              Expanded(
                child: IconButton(
                  icon: Icon(Icons.share, color: Colors.white, size: 24.r),
                  onPressed: () async {
                    // ... (This logic is correct and remains unchanged)
                    final arabicText = quran.getVerse(selectedSura, selectedAyah);
                    final formattedText = '(সূরা ${toBengaliNumber(selectedSura)}, আয়াত ${toBengaliNumber(selectedAyah)}) $arabicText';
                    await Share.share(formattedText);
                    ref.read(selectedAyahProvider.notifier).clear();
                  },
                ),
              ),

              // --- Fullscreen Icon Button (Unchanged) ---
              Expanded(
                child: IconButton(
                  icon: Icon(Icons.fullscreen, color: Colors.white, size: 24.r),
                  onPressed: () {
                    // ... (This logic is correct and remains unchanged)
                    ref.read(barsVisibilityProvider.notifier).hide();
                    ref.read(selectedAyahProvider.notifier).clear();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}