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
  // Inside QuranPage build method
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBoxesAsync = ref.watch(allBoxesProvider);
    final selectedState = ref.watch(selectedAyahProvider); // Watch the selected ayah state
    final logicalPage = pageIndex + 1;
    final pageNumber  = logicalPage < kFirstPageNumber ? -1 : logicalPage;
    final boxes = pageNumber == -1 ? const <AyahBox>[] : ref.watch(boxesForPageProvider(pageNumber));
    final notifier = ref.read(selectedAyahProvider.notifier); // Get the notifier once
    final imgFile = File('${editionDir.path}/qm${pageIndex + 1}.$imageExt');


    return allBoxesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text(e.toString())),
      data:    (_) => LayoutBuilder( // <-- LayoutBuilder is crucial here
        builder: (_, constraints) {
          final scaleX = constraints.maxWidth  / imageWidth;
          final scaleY = constraints.maxHeight / imageHeight;

          // --- Calculate Highlight Rects and Menu Anchor for THIS page ---
          List<Rect> highlightRectsOnThisPage = [];
          Rect? menuAnchorRectOnThisPage;

          // If an ayah is selected globally AND this page is a valid page with boxes
          if (selectedState != null && pageNumber != -1) {
            // Find ALL boxes on *this* page that belong to the selected (sura, ayah)
            final boxesForSelectedAyah = boxes.where(
                  (box) =>
              box.suraNumber == selectedState.suraNumber &&
                  box.ayahNumber == selectedState.ayahNumber,
            ).toList(); // Convert to list to iterate

            if (boxesForSelectedAyah.isNotEmpty) {
              // Calculate scaled rects for highlighting (potentially multiple for multi-line ayah)
              highlightRectsOnThisPage = boxesForSelectedAyah.map((box) {
                return Rect.fromLTWH(
                  box.minX * scaleX,
                  box.minY * scaleY,
                  box.width * scaleX,
                  box.height * scaleY,
                );
              }).toList();

              // Determine the anchor rect for the menu. Usually the first box on the page.
              // Need to be careful about RTL. The first box in the list might not be the visual "first".
              // A simple way is to find the box with the minimum X *on this page*.
              // Or, if boxId increments logically, find the box with the minimum boxId among those on this page.
              final firstBoxOnPageForSelectedAyah = boxesForSelectedAyah.reduce((a, b) => a.boxId < b.boxId ? a : b); // Assumes boxId works

              menuAnchorRectOnThisPage = Rect.fromLTWH(
                firstBoxOnPageForSelectedAyah.minX * scaleX,
                firstBoxOnPageForSelectedAyah.minY * scaleY,
                firstBoxOnPageForSelectedAyah.width * scaleX,
                firstBoxOnPageForSelectedAyah.height * scaleY,
              );

            }
          }
          // --- End Calculate Highlight Rects ---


          // Ensure onTapDown only works when not in touch mode
          void onTapDown(TapDownDetails d) {
            final logicX = d.localPosition.dx / scaleX;
            final logicY = d.localPosition.dy / scaleY;
            // Find boxes on THIS page that contain the tap point
            final tappedBoxes = boxes.where((b) => b.contains(logicX, logicY)).toList();

            if (tappedBoxes.isNotEmpty) {
              final tappedSura = tappedBoxes.first.suraNumber;
              final tappedAyah = tappedBoxes.first.ayahNumber;
              // Use the selectByTap method
              notifier.selectByTap(tappedSura, tappedAyah);
            } else {
              // If no box is tapped, clear the selection
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
                // Pass the calculated list of rects to the highlighter
                // Highlighter will draw all rects in the list
                CustomPaint(
                  painter: AyahHighlighter(highlightRectsOnThisPage), // Pass list of rects
                ),
                // Show menu ONLY if source is tap AND we have a valid anchor rect on this page
                if (selectedState != null && selectedState.source == AyahSelectionSource.tap && menuAnchorRectOnThisPage != null)
                  AyahMenu(anchorRect: menuAnchorRectOnThisPage!), // Use the calculated anchor rect
              ],
            ),
          );
        }, // <-- LayoutBuilder builder ends here
      ), // <-- LayoutBuilder ends here
    );
  }
}
