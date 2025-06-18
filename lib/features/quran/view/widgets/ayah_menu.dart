import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/services/fileChecker.dart';
import '../../model/bookmark.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart'; // Assuming this contains providers like selectedAyahProvider, currentPageProvider, quranInfoServiceProvider, selectedReciterProvider, reciterCatalogueProvider, audioVMProvider, audioPlayerServiceProvider
import '../../../../shared/downloader/download_dialog.dart';
import '../../../../shared/downloader/download_permission_dialog.dart';
import '../../viewmodel/bookmark_viewmodel.dart'; // Assuming this contains bookmarkProvider and BookmarkNotifier

class AyahMenu extends ConsumerWidget {
  const AyahMenu({super.key, required this.anchorRect});

  final Rect anchorRect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    const menuWidth = 250.0;
    const menuHeight = 56.0;
    const verticalOffset = 10.0;

    final selectedAyahState = ref.watch(selectedAyahProvider);
    final bookmarkNotifier = ref.read(bookmarkProvider.notifier);

    final double menuLeft = (screenWidth - menuWidth) / 2;
    final double menuTop = math.max(
      anchorRect.top - menuHeight - verticalOffset,
      0.0,
    );

    if (selectedAyahState == null) {
      return const SizedBox.shrink();
    }

    final selectedSura = selectedAyahState.suraNumber;
    final selectedAyah = selectedAyahState.ayahNumber;
    final currentPage = ref.watch(currentPageProvider) + 1;


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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: IconButton(
                  icon: Icon(
                    isBookmarked
                        ? HugeIcons.solidStandardStackStar
                        : HugeIcons
                              .strokeStandardStackStar,
                    color: isBookmarked
                        ? Colors.orangeAccent
                        : Colors.white,
                  ),
                  onPressed: () {
                    if (!context.mounted) return;
                    if (isBookmarked) {
                      final identifier = 'ayah-$selectedSura-$selectedAyah';
                      bookmarkNotifier.remove(identifier);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('আয়াতটি বুকমার্ক থেকে সরানো হয়েছে')),
                      );
                    } else {
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
                        para: para,
                        page: currentPage,
                      );

                      bookmarkNotifier.add(bookmark);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('আয়াতটি বুকমার্ক করা হয়েছে')),
                      );
                    }
                    ref.read(selectedAyahProvider.notifier).clear();
                  },
                ),
              ),

              // --- Play Audio Icon Button ---
              Expanded(
                child: IconButton(
                  onPressed: () async {
                    // Ensure context is valid
                    if (!context.mounted) return;

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
                                'Audio download permission denied.',
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
                        },
                      );
                    }

                    if (!context.mounted) return; // Check context after dialog

                    // Load timing after download (if needed, depends on your AudioVM logic)
                    // If audioVMProvider's build method watches selectedReciterProvider,
                    // the timings might load automatically when the reciter changes.
                    // Call loadTimings explicitly if you need to guarantee it's loaded
                    // *after* a potential download in this flow.
                    final audioVM = ref.read(audioVMProvider);
                    if (audioVM.value == null || !audioVM.hasValue) {
                      // Timings not loaded, attempt to load them
                      try {
                        await ref.read(audioVMProvider.notifier).loadTimings();
                      } catch (e) {
                        debugPrint('Error loading timings: $e');
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to load audio timings.'),
                            ),
                          );
                        return; // Stop if timings fail to load
                      }
                    }

                    // Proceed with playback
                    // Use the selected ayah from the state
                    final ayahToPlay = ref
                        .read(selectedAyahProvider)!
                        .ayahNumber;
                    final suraToPlay = ref
                        .read(selectedAyahProvider)!
                        .suraNumber;

                    final service = ref.read(audioPlayerServiceProvider);

                    // Make sure AudioControllerService can handle setting sura for playback
                    service.setCurrentSura(
                      suraToPlay,
                    ); // Set the sura for the service

                    await service.playAyahs(
                      ayahToPlay,
                      ayahToPlay,
                    ); // Play only the selected ayah

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

              // --- Other Icons ---
              Expanded(
                child: IconButton(
                  onPressed: () {
                    /* Copy logic */
                  },
                  icon: const Icon(Icons.copy, color: Colors.white),
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: () {
                    /* Share logic */
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: () {
                    /* Fullscreen logic */
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
