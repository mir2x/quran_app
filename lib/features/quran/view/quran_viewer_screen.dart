import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/quran_page.dart';
import '../viewmodel/ayah_highlight_viewmodel.dart';

class QuranViewerScreen extends ConsumerStatefulWidget {
  const QuranViewerScreen({super.key, required this.editionDir});
  final Directory editionDir;

  @override
  ConsumerState<QuranViewerScreen> createState() => _QuranViewerState();
}

class _QuranViewerState extends ConsumerState<QuranViewerScreen> {
  /* controllers */
  late final PageController   _pageCtrl;
  late final ScrollController _scrollCtrl;

  /* page count */
  late final Future<int> _pageCountF;

  /* remember last orientation to prevent unwanted jump */
  Orientation? _prevOrientation;

  /* original scan aspect ratio */
  static const double _aspectRatio = 720 / 1057;

  @override
  void initState() {
    super.initState();
    _pageCtrl   = PageController();
    _scrollCtrl = ScrollController();
    _pageCountF = _detectPageCount();
  }

  Future<int> _detectPageCount() async =>
      await widget.editionDir
          .list()
          .where((f) => f.path.endsWith('.png'))
          .length;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /* jump after orientation change ONLY */
  void _maybeJumpTo(int page, Orientation ori, double itemH) {
    if (_prevOrientation == ori) return;          // same orientation → no jump
    _prevOrientation = ori;                       // remember new orientation
    if (ori == Orientation.portrait) {
      if (_pageCtrl.hasClients) _pageCtrl.jumpToPage(page);
    } else {
      if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(page * itemH);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(currentPageProvider);

    return FutureBuilder<int>(
      future: _pageCountF,
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final pageCount = snap.data!;

        return OrientationBuilder(
          builder: (_, ori) {
            final width     = MediaQuery.of(context).size.width;
            final itemH     = width / _aspectRatio;

            /* jump only when orientation flips */
            WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _maybeJumpTo(currentPage, ori, itemH),
            );

            /* ───────── PORTRAIT: PageView (unchanged) ───────── */
            if (ori == Orientation.portrait) {
              return Scaffold(
                body: PageView.builder(
                  controller: _pageCtrl,
                  reverse: true,
                  itemCount: pageCount,
                  onPageChanged: (idx) {
                    ref.read(selectedAyahProvider.notifier).clear();
                    ref.read(currentPageProvider.notifier).state = idx;
                  },
                  itemBuilder: (_, idx) => QuranPage(
                    pageIndex: idx,
                    editionDir: widget.editionDir,
                  ),
                ),
              );
            }

            /* ───────── LANDSCAPE: free vertical scroll ───────── */
            return Scaffold(
              body: NotificationListener<ScrollUpdateNotification>(
                onNotification: (n) {
                  final page = (n.metrics.pixels / itemH)
                      .round()
                      .clamp(0, math.max(0, pageCount - 1));
                  if (page != currentPage) {
                    ref.read(currentPageProvider.notifier).state = page.toInt();
                    ref.read(selectedAyahProvider.notifier).clear();
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: List.generate(
                      pageCount,
                          (idx) => SizedBox(
                        height: itemH,
                        width: double.infinity,
                        child: QuranPage(
                          pageIndex: idx,
                          editionDir: widget.editionDir,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
