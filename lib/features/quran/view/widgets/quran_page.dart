import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/core/services/audio_service.dart';
import '../../../../core/constants.dart';
import '../../model/ayah_box.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart';
import 'ayah_highlighter.dart';
import 'ayah_menu.dart';


class QuranPage extends ConsumerWidget {
  final int pageIndex;
  final Directory editionDir;
  final int imageWidth;
  final int imageHeight;
  final String imageExt;
  const QuranPage({super.key, required this.pageIndex, required this.editionDir, required this.imageWidth, required this.imageHeight, required this.imageExt,});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBoxesAsync = ref.watch(allBoxesProvider);
    final selectedState = ref.watch(selectedAyahProvider);
    final logicalPage = pageIndex + 1;
    final pageNumber  = logicalPage < kFirstPageNumber
        ? -1
        : logicalPage;
    final boxes = pageNumber == -1
        ? const <AyahBox>[]
        : ref.watch(boxesForPageProvider(pageNumber));
    final notifier      = ref.read(selectedAyahProvider.notifier);
    final selected      = ref.watch(selectedAyahProvider);
    final imgFile = File('${editionDir.path}/qm${pageIndex + 1}.$imageExt');



    return allBoxesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text(e.toString())),
      data:    (_) => LayoutBuilder(
        builder: (_, constraints) {
          final scaleX = constraints.maxWidth  / imageWidth;
          final scaleY = constraints.maxHeight / imageHeight;

          if (selectedState != null && selectedState.anchorRect == Rect.zero && pageNumber != -1) {
            if (selectedState.suraNumber != null && selectedState.ayahNumber != null) {
              final firstBoxOnPage = boxes.firstWhereOrNull(
                    (box) =>
                box.suraNumber == selectedState.suraNumber &&
                    box.ayahNumber == selectedState.ayahNumber,
              );

              if (firstBoxOnPage != null) {
                // If the box exists on this page, calculate its scaled rect and update the state.
                final scaleX = constraints.maxWidth  / imageWidth;
                final scaleY = constraints.maxHeight / imageHeight;

                final calculatedRect = Rect.fromLTWH(
                  firstBoxOnPage.minX * scaleX,
                  firstBoxOnPage.minY * scaleY,
                  firstBoxOnPage.width * scaleX,
                  firstBoxOnPage.height * scaleY,
                );

                // Use Future.microtask to avoid calling setState during build/layout
                Future.microtask(() {
                  // Update the provider with the calculated Rect, but keep sura/ayah the same
                  // Need a method in the notifier for this, or update the state directly.
                  // Let's add an updateRect method.
                  // notifier.updateRect(calculatedRect); // Assuming you add this method
                  // OR
                  ref.read(selectedAyahProvider.notifier).state = selectedState.copyWith(anchorRect: calculatedRect); // If using copyWith
                });
              }
              // If firstBoxOnPage is null, the selected ayah is not on this page,
              // so we don't highlight anything on this page.
            }
          }

          void onTapDown(TapDownDetails d) {
            final logicX = d.localPosition.dx / scaleX;
            final logicY = d.localPosition.dy / scaleY;
            final tapped = boxes.where((b) => b.contains(logicX, logicY)).toList();
            if (tapped.isNotEmpty) {
              final tappedSura = tapped.first.suraNumber;
              final tappedAyah = tapped.first.ayahNumber;

              final firstBoxOnPage = boxes
                  .where((b) => b.suraNumber == tappedSura && b.ayahNumber == tappedAyah)
                  .reduce((a, b) => a.boxId < b.boxId ? a : b);
              final rect = Rect.fromLTWH(
                firstBoxOnPage.minX * scaleX,
                firstBoxOnPage.minY * scaleY,
                firstBoxOnPage.width * scaleX,
                firstBoxOnPage.height * scaleY,
              );
              notifier.select(tappedSura, tappedAyah, rect);
            } else {
              notifier.clear();
            }
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: ref.watch(touchModeProvider) ? null : onTapDown,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  imgFile,
                  fit: BoxFit.fill,
                ),
                CustomPaint(
                  // Pass the sura number to highlighter too if needed for logic
                  painter: AyahHighlighter(
                      boxes, selectedState?.suraNumber, selectedState?.ayahNumber, scaleX, scaleY), // Pass suraNumber
                ),
                // Only show menu if there's a selected state AND the Rect is valid (not Rect.zero)
                if (selectedState != null && selectedState.anchorRect != Rect.zero)
                  AyahMenu(anchorRect: selectedState.anchorRect),
              ],
            ),
          );
        },
      ),
    );
  }
}
