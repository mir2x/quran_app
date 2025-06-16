import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/services/fileChecker.dart';
import '../../model/bookmark.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart';
import '../../../../shared/downloader/download_dialog.dart';
import '../../../../shared/downloader/download_permission_dialog.dart';

class AyahMenu extends ConsumerWidget {
  const AyahMenu({super.key, required this.anchorRect});

  final Rect anchorRect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    const menuWidth = 300.0;
    const menuHeight = 56.0;
    const verticalOffset = 10.0;

    return Positioned(
      left: (screenWidth - menuWidth) / 2,
      top: math.max(anchorRect.top - menuHeight - verticalOffset, 0),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        child: SizedBox(
          height: menuHeight,
          width: menuWidth,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  final selectedAyahState = ref.read(selectedAyahProvider);
                  final currentPage = ref.read(currentPageProvider) + 1; // 1-based page
                  final quranInfoService = ref.read(quranInfoServiceProvider); // Read the service provider

                  if (selectedAyahState != null) {
                    final sura = selectedAyahState.suraNumber;
                    final ayah = selectedAyahState.ayahNumber;

                    final para = quranInfoService.getParaBySuraAyah(sura, ayah); // Get Para from Sura/Ayah
                    final page = currentPage; // The page the user is currently viewing

                    // Consider using 'ayah-${sura}-${ayah}' as identifier for uniqueness and future proofing
                    final identifier = 'ayah-$sura-$ayah'; // Unique identifier for ayah bookmark

                    final bookmark = Bookmark(
                      type: 'ayah',
                      identifier: identifier,
                      sura: sura,
                      ayah: ayah,
                      para: para,
                      page: page,
                    );

                    ref.read(bookmarkProvider.notifier).add(bookmark);
                  } else {
                    // Handle case where no ayah is selected (shouldn't happen if button is only visible when ayah is selected)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No Ayah selected to bookmark')),
                    );
                  }
                },
                icon: const Icon(HugeIcons.solidStandardStackStar),
              ),
              IconButton(
                onPressed: () async {
                  final reciterId = ref.read(selectedReciterProvider);
                  final downloaded = await isAssetDownloaded(reciterId);
                  if (!downloaded) {
                    final reciter = ref
                        .read(reciterCatalogueProvider)
                        .firstWhere((r) => r.id == reciterId);
                    final confirmed = await downloadPermissionDialog(
                      context,
                      "audio",
                      reciterName:  reciter.name,
                    );
                    if (!confirmed) return;
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => DownloadDialog(id: reciter.id, zipUrl: reciter.zipUrl, sizeBytes: reciter.sizeBytes),
                    );
                  }
                  await ref.read(audioVMProvider.notifier).loadTimings();
                  final ayah = ref.read(selectedAyahProvider)!.ayahNumber;
                  ref.read(audioPlayerServiceProvider).playAyahs(ayah, ayah);
                },
                icon: const Icon(HugeIcons.solidRoundedPlay),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.copy)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.copy)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.copy)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.copy)),
            ],
          ),
        ),
      ),
    );
  }
}
