import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants.dart';
import '../../model/ayah_box.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart';
import '../quran_viewer_screen.dart';
import 'ayah_highlighter.dart';


class QuranPage extends ConsumerWidget {
  const QuranPage({super.key, required this.pageIndex, required this.editionDir});
  final int pageIndex;
  final Directory editionDir;

  static const double _imgW = 720;
  static const double _imgH = 1057;

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
    final imgFile = File('${editionDir.path}/qm${pageIndex + 1}.png');

    return allBoxesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text(e.toString())),
      data:    (_) => LayoutBuilder(
        builder: (_, constraints) {
          final scaleX = constraints.maxWidth  / _imgW;
          final scaleY = constraints.maxHeight / _imgH;

          void onTapDown(TapDownDetails d) {
            final logicX = d.localPosition.dx / scaleX;
            final logicY = d.localPosition.dy / scaleY;
            final tapped = boxes.where((b) => b.contains(logicX, logicY)).toList();
            if (tapped.isNotEmpty) {
              final ayah = tapped.first.ayahNumber;
              final firstBox = boxes
                  .where((b) => b.ayahNumber == ayah)
                  .reduce((a, b) => a.boxId < b.boxId ? a : b);
              final rect = Rect.fromLTWH(
                firstBox.minX * scaleX,
                firstBox.minY * scaleY,
                firstBox.width * scaleX,
                firstBox.height * scaleY,
              );
              notifier.select(ayah, rect);
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
                  painter: AyahHighlighter(
                      boxes, selected?.ayahNumber, scaleX, scaleY),
                ),
                if (selectedState != null)
                  AyahMenu(anchorRect: selectedState.anchorRect),
              ],
            ),
          );
        },
      ),
    );
  }
}
