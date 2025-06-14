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
                  final ayah = ref.read(selectedAyahProvider)?.ayahNumber;
                  final page = ref.read(currentPageProvider);
                  if (ayah != null) {
                    final identifier = 'ayah-$page:$ayah';
                    ref
                        .read(bookmarkProvider.notifier)
                        .add(Bookmark(type: 'ayah', identifier: identifier));
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
