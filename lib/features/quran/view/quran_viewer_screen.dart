// lib/features/quran/view/quran_viewer_screen.dart

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';        // primaryColor, bottomBarHeight
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

  /* track last orientation → only jump when it changes */
  Orientation? _prevOri;

  /* asset aspect ratio */
  static const double _aspect = 720 / 1057;

  /* dummy reciters for the dropdown */
  static const List<String> reciters = ['Al-Afasy', 'Al-Hudhaify', 'Abdul Basit'];

  @override
  void initState() {
    super.initState();
    _pageCtrl   = PageController();
    _scrollCtrl = ScrollController();
    _pageCountF = _detectPageCount();
  }

  Future<int> _detectPageCount() async =>
      await widget.editionDir.list().where((e) => e.path.endsWith('.png')).length;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /* ───────────────── helpers ───────────────── */

  void _jumpTo(int page, Orientation ori, double itemH) {
    if (_prevOri == ori) return;                   // same orientation? skip
    _prevOri = ori;
    if (ori == Orientation.portrait) {
      if (_pageCtrl.hasClients) _pageCtrl.jumpToPage(page);
    } else {
      if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(page * itemH);
    }
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
    title: const Text('কুরআন মজীদ',
        style: TextStyle(fontFamily: 'SolaimanLipi', fontSize: 22)),
    centerTitle: true,
    actions: [
      IconButton(icon: const Icon(Icons.search), onPressed: () {}),
      IconButton(icon: const Icon(Icons.nightlight_outlined), onPressed: () {}),
      IconButton(icon: const Icon(Icons.g_translate), onPressed: () {}),
    ],
  );

  Widget _buildBottomBar() => BottomAppBar(
    height: bottomBarHeight,
    child: Row(
      children: [
        /* 1️⃣  Left icon — fixed size */
        IconButton(icon: const Icon(Icons.play_arrow), onPressed: () {}),

        /* 2️⃣  Reciter selector — EXPANDED so it steals / releases width */
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: reciters.first,
              isExpanded: true,                   // <-- important
              items: reciters
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (_) {},
            ),
          ),
        ),

        /* 3️⃣  Trailing icons wrapped in a Row with minimal space */
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.touch_app_outlined), onPressed: () {}),
            IconButton(icon: const Icon(Icons.screen_rotation_outlined), onPressed: () {}),
            IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
            IconButton(icon: const Icon(Icons.arrow_upward_outlined), onPressed: () {}),
          ],
        ),
      ],
    ),
  );


  /* ───────────────── main build ───────────────── */

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(currentPageProvider);

    return FutureBuilder<int>(
      future: _pageCountF,
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final pageCount = snap.data!;

        return OrientationBuilder(
          builder: (_, ori) {
            final width  = MediaQuery.of(context).size.width;
            final itemH  = width / _aspect;

            /* jump exactly once after each orientation change */
            WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _jumpTo(currentPage, ori, itemH),
            );

            Widget body;
            if (ori == Orientation.portrait) {
              body = PageView.builder(
                controller: _pageCtrl,
                reverse: true,
                itemCount: pageCount,
                onPageChanged: (idx) =>
                ref.read(currentPageProvider.notifier).state = idx,
                itemBuilder: (_, idx) => QuranPage(
                  pageIndex: idx,
                  editionDir: widget.editionDir,
                ),
              );
            } else {
              body = NotificationListener<ScrollUpdateNotification>(
                onNotification: (n) {
                  final p = (n.metrics.pixels / itemH)
                      .round()
                      .clamp(0, math.max(0, pageCount - 1));
                  if (p != currentPage) {
                    ref.read(currentPageProvider.notifier).state = p.toInt();
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
                        child: QuranPage(
                          pageIndex: idx,
                          editionDir: widget.editionDir,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Scaffold(
              appBar: _buildAppBar(),
              bottomNavigationBar: _buildBottomBar(),
              body: body,
            );
          },
        );
      },
    );
  }
}
