import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants.dart';
import '../../model/ayah_box.dart';
import '../../viewmodels/ayah_highlight_viewmodel.dart';
import 'ayah_highlighter.dart';


class QuranPage extends ConsumerWidget {
  const QuranPage({super.key, required this.pageIndex});
  final int pageIndex;

  static const double _imgW = 720;
  static const double _imgH = 1057;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBoxesAsync = ref.watch(allBoxesProvider);       // load once
    final boxes         = ref.watch(boxesForPageProvider(pageIndex));
    final notifier      = ref.read(selectedAyahProvider.notifier);
    final selected      = ref.watch(selectedAyahProvider);

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
            final tapped = boxes.firstWhere(
                  (b) => b.contains(logicX, logicY),
              orElse: () => const AyahBox(
                ayahNumber: -1, boxId: -1,
                minX: 0, minY: 0, maxX: 0, maxY: 0,
                pageNumber: 0, suraNumber: 0,
              ),
            );
            if (tapped.ayahNumber != -1) {
              notifier.select(tapped.ayahNumber);
            }
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: onTapDown,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _imgPathFor(pageIndex),
                  fit: BoxFit.fill,
                ),
                CustomPaint(
                  painter: AyahHighlighter(
                      boxes, selected, scaleX, scaleY),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _imgPathFor(int idx) {
    final num = kFirstPageNumber + idx;
    return 'assets/page_${num.toString().padLeft(3, '0')}.png';
  }
}
