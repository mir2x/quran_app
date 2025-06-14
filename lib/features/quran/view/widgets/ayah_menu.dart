import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/bookmark.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart';

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
                    ref.read(bookmarkProvider.notifier).add(
                      Bookmark(type: 'ayah', identifier: identifier),
                    );
                  }
                },
                icon: const Icon(Icons.bookmark),
              ),
              IconButton(onPressed: () {
                ref.read(navigateToPageCommandProvider.notifier).state = 5;
              }, icon: const Icon(Icons.copy)),
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