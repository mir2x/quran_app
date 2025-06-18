import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for Clipboard
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:quran/quran.dart' as quran; // Import the quran package
import 'package:share_plus/share_plus.dart'; // Import share_plus
import '../../../../core/services/fileChecker.dart';
import '../../model/bookmark.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart'; // Assuming this contains providers like selectedAyahProvider, currentPageProvider, quranInfoServiceProvider, selectedReciterProvider, reciterCatalogueProvider, audioVMProvider, audioPlayerServiceProvider
import '../../../../shared/downloader/download_dialog.dart';
import '../../../../shared/downloader/download_permission_dialog.dart';
import '../../viewmodel/bookmark_viewmodel.dart'; // Assuming this contains bookmarkProvider and BookmarkNotifier

class AyahMenu extends ConsumerWidget {
  const AyahMenu({super.key, required this.anchorRect});

  final Rect anchorRect;

  // Helper function to convert Latin numbers to Bengali numbers
  String toBengaliNumber(int number) {
    const latinNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bengaliNumbers = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

    String numberStr = number.toString();
    String bengaliStr = '';

    for (int i = 0; i < numberStr.length; i++) {
      int digit = int.parse(numberStr[i]);
      bengaliStr += bengaliNumbers[digit];
    }
    return bengaliStr;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    const menuWidth = 300.0; // Increased width to accommodate more icons
    const menuHeight = 60.0;
    const verticalOffset = 10.0;

    final selectedAyahState = ref.watch(selectedAyahProvider);
    final bookmarkNotifier = ref.read(bookmarkProvider.notifier);

    // Calculate the position of the menu
    // Place it above the anchorRect, centered horizontally
    final double menuLeft = (screenWidth - menuWidth) / 2;
    // Ensure it doesn't go off the top of the screen
    final double menuTop = math.max(
      anchorRect.top - menuHeight - verticalOffset,
      0.0,
    );

    // If no ayah is selected, maybe hide the menu entirely?
    if (selectedAyahState == null) {
      return const SizedBox.shrink();
    }

    // Get details of the currently selected ayah
    final selectedSura = selectedAyahState.suraNumber;
    final selectedAyah = selectedAyahState.ayahNumber;
    final currentPage = ref.watch(currentPageProvider) + 1; // 1-based page

    // Watch the bookmark provider to react to changes in bookmarks
    // Although we don't directly use bookmarksAsync.value here,
    // watching it ensures this widget rebuilds when the list changes,
    // which is necessary for isAyahBookmarked to reflect the latest state.
    final bookmarksAsync = ref.watch(bookmarkProvider);


    // Determine if the selected ayah is currently bookmarked
    final bool isBookmarked = bookmarkNotifier.isAyahBookmarked(
      selectedSura,
      selectedAyah,
    );

    return Positioned(
      left: menuLeft,
      top: menuTop,
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF294B39),
        child: SizedBox(
          height: menuHeight,
          width: menuWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute icons evenly
            children: [
              // --- Bookmark Icon Button ---
              Expanded(
                child: IconButton(
                  icon: Icon(
                    isBookmarked
                        ? HugeIcons.solidStandardStackStar
                        : HugeIcons
                        .strokeStandardStackStar, // Filled or Stroke icon
                    color: isBookmarked
                        ? Colors.orangeAccent
                        : Colors.white, // Change color when bookmarked
                  ),
                  onPressed: () {
                    if (!context.mounted) return; // Check context validity

                    if (isBookmarked) {
                      // Remove bookmark
                      final identifier = 'ayah-$selectedSura-$selectedAyah';
                      bookmarkNotifier.remove(identifier);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('আয়াতটি বুকমার্ক থেকে সরানো হয়েছে')), // Bengali removed message
                      );
                    } else {
                      // Add bookmark
                      final quranInfoService = ref.read(
                        quranInfoServiceProvider,
                      );
                      final para = quranInfoService.getParaBySuraAyah(
                        selectedSura,
                        selectedAyah,
                      );

                      final identifier = 'ayah-$selectedSura-$selectedAyah';

                      final bookmark = Bookmark(
                        type: 'ayah',
                        identifier: identifier,
                        sura: selectedSura,
                        ayah: selectedAyah,
                        para: para, // Get para using the service
                        page: currentPage, // Use the current page
                      );

                      bookmarkNotifier.add(bookmark);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('আয়াতটি বুকমার্ক করা হয়েছে')), // Bengali added message
                      );
                    }
                    // Hide the menu after bookmarking/unbookmarking
                    ref
                        .read(selectedAyahProvider.notifier)
                        .clear(); // Clear selected ayah hides the menu
                  },
                ),
              ),

              // --- Play Audio Icon Button ---
              Expanded(
                child: IconButton(
                  onPressed: () async {
                    if (!context.mounted) return; // Check context validity

                    final reciterId = ref.read(selectedReciterProvider);
                    final downloaded = await isAssetDownloaded(reciterId);

                    if (!downloaded) {
                      final reciter = ref
                          .read(reciterCatalogueProvider)
                          .firstWhere((r) => r.id == reciterId);

                      // Use context from the builder
                      final confirmed = await downloadPermissionDialog(
                        context,
                        "audio",
                        reciterName: reciter.name,
                      );
                      if (!confirmed) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'অডিও ডাউনলোডের অনুমতি দেওয়া হয়নি।', // Bengali: Audio download permission denied.
                              ),
                            ),
                          );
                        }
                        return;
                      }

                      if (!context.mounted) return; // Check context again
                      await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext dialogContext) {
                            // Use a new context for the dialog
                            return DownloadDialog(
                              id: reciter.id,
                              zipUrl: reciter.zipUrl,
                              sizeBytes: reciter.sizeBytes,
                            );
                          });
                    }

                    if (!context.mounted) return; // Check context after dialog

                    // Ensure timing data is loaded
                    final audioVM = ref.read(audioVMProvider);
                    if (audioVM.value == null || !audioVM.hasValue) {
                      try {
                        await ref.read(audioVMProvider.notifier).loadTimings();
                      } catch (e) {
                        debugPrint('Error loading timings: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'অডিও টাইমিং লোড করতে ব্যর্থ হয়েছে।'), // Bengali: Failed to load audio timings.
                            ),
                          );
                        }
                        return; // Stop if timings fail to load
                      }
                    }

                    // Proceed with playback
                    final ayahToPlay =
                        ref.read(selectedAyahProvider)!.ayahNumber;
                    final suraToPlay =
                        ref.read(selectedAyahProvider)!.suraNumber;

                    final service = ref.read(audioPlayerServiceProvider);

                    service.setCurrentSura(
                        suraToPlay); // Set the sura for the service

                    await service.playAyahs(
                        ayahToPlay, ayahToPlay); // Play only the selected ayah

                    // Hide the menu after starting playback (common UX)
                    if (context.mounted) {
                      ref
                          .read(selectedAyahProvider.notifier)
                          .clear(); // Clear selected ayah hides the menu
                    }
                  },
                  icon: const Icon(
                    HugeIcons.solidRoundedPlay,
                    color: Colors.white,
                  ),
                ),
              ),

              // --- Copy Icon Button ---
              Expanded(
                child: IconButton(
                  onPressed: () async {
                    if (!context.mounted) return; // Check context validity

                    // Get selected Ayah details
                    final selectedAyahState = ref.read(selectedAyahProvider);
                    if (selectedAyahState == null) {
                      // This case should technically not happen if the menu is only visible
                      // when an ayah is selected, but good for robustness.
                      return;
                    }
                    final sura = selectedAyahState.suraNumber;
                    final ayah = selectedAyahState.ayahNumber;

                    // Get the Arabic text using the quran package
                    final arabicText = quran.getVerse(sura, ayah);

                    // Convert Sura and Ayah numbers to Bengali
                    final bengaliSura = toBengaliNumber(sura);
                    final bengaliAyah = toBengaliNumber(ayah);

                    // Format the text
                    final formattedText =
                        '(সূরা $bengaliSura, আয়াত $bengaliAyah) $arabicText';

                    // Copy to clipboard
                    await Clipboard.setData(ClipboardData(text: formattedText));

                    // Show confirmation Snackbar in Bengali
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('আয়াতটি কপি করা হয়েছে')), // Bengali: Ayah copied
                    );

                    // Hide the menu after copying
                    ref.read(selectedAyahProvider.notifier).clear();
                  },
                  icon: const Icon(Icons.copy, color: Colors.white),
                ),
              ),

              // --- Share Icon Button ---
              Expanded(
                child: IconButton(
                  onPressed: () async {
                    if (!context.mounted) return; // Check context validity

                    // Get selected Ayah details (same as copy)
                    final selectedAyahState = ref.read(selectedAyahProvider);
                    if (selectedAyahState == null) {
                      return;
                    }
                    final sura = selectedAyahState.suraNumber;
                    final ayah = selectedAyahState.ayahNumber;

                    // Get the Arabic text
                    final arabicText = quran.getVerse(sura, ayah);

                    // Convert Sura and Ayah numbers to Bengali
                    final bengaliSura = toBengaliNumber(sura);
                    final bengaliAyah = toBengaliNumber(ayah);

                    // Format the text
                    final formattedText =
                        '(সূরা $bengaliSura, আয়াত $bengaliAyah) $arabicText';

                    // Share the text
                    await Share.share(formattedText);

                    // Hide the menu after sharing
                    ref.read(selectedAyahProvider.notifier).clear();
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                ),
              ),

              // --- Fullscreen Icon Button ---
              Expanded(
                child: IconButton(
                  onPressed: () {
                    ref.read(barsVisibilityProvider.notifier).hide();
                    ref.read(drawerOpenProvider.notifier).close();
                    ref.read(selectedAyahProvider.notifier).clear();
                  },
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}