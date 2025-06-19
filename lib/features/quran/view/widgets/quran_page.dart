import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import screenutil
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants.dart';
import '../../model/ayah_box.dart';
import '../../model/selected_ayah_state.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart';
import 'ayah_highlighter.dart';
import 'ayah_menu.dart';

class QuranPage extends ConsumerWidget {
  final int pageIndex;
  final Directory editionDir;
  final int imageWidth;
  final int imageHeight;
  final String imageExt;
  const QuranPage({
    super.key,
    required this.pageIndex,
    required this.editionDir,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageExt,
  });


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBoxesAsync = ref.watch(allBoxesProvider);
    final selectedState = ref.watch(selectedAyahProvider);
    final touchModeOn = ref.watch(touchModeProvider);

    final logicalPage = pageIndex + 1;
    final pageNumber  = logicalPage < kFirstPageNumber ? -1 : logicalPage;
    // boxesForPageProvider already fetches boxes based on the *logical* page number,
    // and the scaling logic below handles mapping these box coordinates
    // to the screen coordinates. No changes needed here regarding page numbers.
    final boxes = pageNumber == -1 ? const <AyahBox>[] : ref.watch(boxesForPageProvider(pageNumber));
    final notifier = ref.read(selectedAyahProvider.notifier);
    final imgFile = File('${editionDir.path}/qm${pageIndex + 1}.$imageExt');

    final bool isSelectedAyahOnThisPage = selectedState != null &&
        pageNumber != -1 &&
        boxes.any((box) => box.suraNumber == selectedState.suraNumber && box.ayahNumber == selectedState.ayahNumber);

    final bool showMenuOnThisPage = selectedState != null &&
        selectedState.source == AyahSelectionSource.tap &&
        isSelectedAyahOnThisPage;

    void onTapDown(TapDownDetails d, double scaleX, double scaleY, List<AyahBox> currentPageBoxes) {

      if (selectedState != null && selectedState.source == AyahSelectionSource.tap) {
        notifier.clear();
        return;
      }

      if (!touchModeOn) {
        // LogicX and logicY calculations remain based on the raw coordinates
        // and the scale factors derived from the image dimensions and screen constraints.
        // ScreenUtil is not applied directly here as these are calculations
        // to find which *ayah box* was tapped based on the raw input.
        final logicX = d.localPosition.dx / scaleX;
        final logicY = d.localPosition.dy / scaleY;
        final tappedBoxes = currentPageBoxes.where((b) => b.contains(logicX, logicY)).toList();

        if (tappedBoxes.isNotEmpty) {
          final tappedSura = tappedBoxes.first.suraNumber;
          final tappedAyah = tappedBoxes.first.ayahNumber;
          notifier.selectByTap(tappedSura, tappedAyah);
        } else {
        }
      }
    }

    return allBoxesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(
        child: Text(
          e.toString(),
          // Optional: Scale text in error message
          style: TextStyle(fontSize: 14.sp),
        ),
      ),
      data:    (_) => LayoutBuilder(
        builder: (_, constraints) {
          // scaleX and scaleY calculations remain based on comparing
          // layout constraints to image dimensions. This is the core of
          // scaling the ayah box coordinates.
          final scaleX = constraints.maxWidth  / imageWidth;
          final scaleY = constraints.maxHeight / imageHeight;

          List<Rect> highlightRectsOnThisPage = [];
          Rect? menuAnchorRectOnThisPage;

          if (selectedState != null && isSelectedAyahOnThisPage) {

            final boxesForSelectedAyah = boxes.where(
                  (box) =>
              box.suraNumber == selectedState.suraNumber &&
                  box.ayahNumber == selectedState.ayahNumber,
            ).toList();

            if (boxesForSelectedAyah.isNotEmpty) {
              highlightRectsOnThisPage = boxesForSelectedAyah.map((box) {
                // Highlight rects are scaled using the calculated scaleX and scaleY
                // which is the correct approach for mapping the box coordinates
                // to the current screen size. ScreenUtil is not applied directly here.
                return Rect.fromLTWH(
                  box.minX * scaleX,
                  box.minY * scaleY,
                  box.width * scaleX,
                  box.height * scaleY,
                );
              }).toList();

              try {
                final firstBoxOnPageForSelectedAyah = boxesForSelectedAyah.reduce((a, b) => a.boxId < b.boxId ? a : b);

                // Menu anchor rect is also scaled using scaleX and scaleY
                menuAnchorRectOnThisPage = Rect.fromLTWH(
                  firstBoxOnPageForSelectedAyah.minX * scaleX,
                  firstBoxOnPageForSelectedAyah.minY * scaleY,
                  firstBoxOnPageForSelectedAyah.width * scaleX,
                  firstBoxOnPageForSelectedAyah.height * scaleY,
                );
              } catch (e) {
                debugPrint("Error finding first box for selected ayah on page $pageNumber: $e");
                menuAnchorRectOnThisPage = null;
              }
            }
          }
          return Stack(
            fit: StackFit.expand, // Stack fills the available space
            children: [
              // Image takes the available space, its aspect ratio is handled by the parent
              Image.file(
                imgFile,
                fit: BoxFit.fill, // Fills the available space, potentially distorting if aspect ratio is not maintained by parent
              ),
              // AyahHighlighter CustomPaint uses the scaled Rects, so no direct ScreenUtil needed here.
              CustomPaint(
                painter: AyahHighlighter(highlightRectsOnThisPage),
              ),

              // GestureDetector covers the image to detect taps.
              // Its behavior and size are tied to the parent Stack's size.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => onTapDown(details, scaleX, scaleY, boxes),

                child: Container(), // An empty container makes the GestureDetector cover the area
              ),

              // AyahMenu positioning is handled by AyahMenu itself relative to the anchorRect.
              // Any internal padding, font sizes, etc. within AyahMenu should use ScreenUtil.
              if (showMenuOnThisPage && menuAnchorRectOnThisPage != null)
                AyahMenu(anchorRect: menuAnchorRectOnThisPage!),
            ],
          );
        }, // <-- LayoutBuilder builder ends here
      ), // <-- LayoutBuilder ends here
    );
  }
}