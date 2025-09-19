import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final pageInfo = ref.watch(pageInfoProvider(logicalPage));

    final int currentPageNumber = pageInfo.pageNumber;
    final int? currentParaNumber = pageInfo.paraNumber;
    final List<int> surasOnThisPage = pageInfo.surasOnPage;

    print('Page: $currentPageNumber, Para: $currentParaNumber');
    for (final sura in surasOnThisPage) {
      final (startAyah, endAyah) = pageInfo.suraAyahRanges[sura]!;
      print('Sura $sura is on this page from ayah $startAyah to $endAyah.');
    }


    final pageNumber  = logicalPage < kFirstPageNumber ? -1 : logicalPage;
    final boxes = pageNumber == -1 ? const <AyahBox>[] : ref.watch(boxesForPageProvider(pageNumber));
    final notifier = ref.read(selectedAyahProvider.notifier);
    final imgFile = File('${editionDir.path}/qm${pageIndex + 1}.$imageExt');

    final bool isSelectedAyahOnThisPage = selectedState != null &&
        pageNumber != -1 &&
        boxes.any((box) => box.suraNumber == selectedState.suraNumber && box.ayahNumber == selectedState.ayahNumber);

    final bool showMenuOnThisPage = selectedState != null &&
        selectedState.source == AyahSelectionSource.tap &&
        isSelectedAyahOnThisPage;

    void onTapDown(
        TapDownDetails d,
        double scaleX,
        double scaleY,
        List<AyahBox> currentPageBoxes,
        ) {
      final logicX = d.localPosition.dx / scaleX;
      final logicY = d.localPosition.dy / scaleY;
      final tappedBoxes = currentPageBoxes.where((b) => b.contains(logicX, logicY)).toList();

      if (tappedBoxes.isNotEmpty) {
        final tappedSura = tappedBoxes.first.suraNumber;
        final tappedAyah = tappedBoxes.first.ayahNumber;

        if (selectedState != null &&
            selectedState.source == AyahSelectionSource.tap &&
            selectedState.suraNumber == tappedSura &&
            selectedState.ayahNumber == tappedAyah) {
          notifier.clear();
        } else {
          notifier.selectByTap(tappedSura, tappedAyah);
        }
      } else {
        notifier.clear();
      }
    }


    return allBoxesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(
        child: Text(
          e.toString(),
          style: TextStyle(fontSize: 14.sp),
        ),
      ),
      data:    (_) => LayoutBuilder(
        builder: (_, constraints) {
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
                return Rect.fromLTWH(
                  box.minX * scaleX,
                  box.minY * scaleY,
                  box.width * scaleX,
                  box.height * scaleY,
                );
              }).toList();

              try {
                final firstBoxOnPageForSelectedAyah = boxesForSelectedAyah.reduce((a, b) => a.boxId < b.boxId ? a : b);
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
            fit: StackFit.expand,
            children: [
              Image.file(
                imgFile,
                fit: BoxFit.fill,
              ),
              CustomPaint(
                painter: AyahHighlighter(highlightRectsOnThisPage),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => onTapDown(details, scaleX, scaleY, boxes),
                child: Container(),
              ),
              if (showMenuOnThisPage && menuAnchorRectOnThisPage != null)
                AyahMenu(anchorRect: menuAnchorRectOnThisPage),
            ],
          );
        }, //
      ), //
    );
  }
}