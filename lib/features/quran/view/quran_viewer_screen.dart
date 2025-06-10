import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/quran/view/widgets/quran_page.dart';

import '../viewmodels/ayah_highlight_viewmodel.dart';

class QuranViewerScreen extends ConsumerStatefulWidget {
  const QuranViewerScreen({super.key, required this.pageCount});
  final int pageCount;

  @override
  ConsumerState<QuranViewerScreen> createState() => _QuranViewerState();
}

class _QuranViewerState extends ConsumerState<QuranViewerScreen> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.pageCount,
        reverse: true,
        onPageChanged: (_) =>
            ref.read(selectedAyahProvider.notifier).clear(), // reset highlight
        itemBuilder: (_, idx) => QuranPage(pageIndex: idx),
      ),
    );
  }
}
