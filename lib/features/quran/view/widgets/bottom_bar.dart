import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../model/bookmark.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart';
import 'audio_bottom_sheet.dart';

class BottomBar extends ConsumerWidget {
  final bool drawerOpen;
  final GlobalKey<ScaffoldState> rootKey;

  const BottomBar({super.key, required this.drawerOpen, required this.rootKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedReciter = ref.watch(selectedReciterProvider);
    final displayReciterName = reciters.entries
        .firstWhere((e) => e.value == selectedReciter)
        .key;

    return BottomAppBar(
      height: 64,
      color: const Color(0xFF294B39),
      padding: EdgeInsets.zero, // remove side gap
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _iconBtn(
            icon: HugeIcons.solidRoundedPlay,
            onPressed: () {
              final sura = ref.watch(currentSuraProvider);
              final page = ref.watch(currentPageProvider);
              debugPrint(sura.toString());
              debugPrint(page.toString());

              showModalBottomSheet(
                context: context,
                builder: (_) => AudioBottomSheet(currentSura: sura),
              );
            },
          ),

          Expanded(
            child: Container(
              height: 40,
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF294B39),
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: const Color(0xFF294B39),
                  iconEnabledColor: Colors.white,
                  style: const TextStyle(color: Colors.white),
                  value: displayReciterName,
                  items: reciters.keys.map((displayName) {
                    return DropdownMenuItem(
                      value: displayName,
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(selectedReciterProvider.notifier).state =
                      reciters[val]!;
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Consumer(
            builder: (_, ref, __) {
              final on = ref.watch(touchModeProvider);
              return _iconBtn(
                icon: HugeIcons.solidStandardTouchLocked04,
                color: on ? Colors.orangeAccent : Colors.white,
                size: 26,
                onPressed: () {
                  ref.read(touchModeProvider.notifier).toggle();
                  if (!ref.read(touchModeProvider)) return;
                  ref.read(selectedAyahProvider.notifier).clear();
                },
              );
            },
          ),
          _iconBtn(
            icon: HugeIcons.solidSharpScreenRotation,
            onPressed: () => OrientationToggle.toggle(),
          ),
          _iconBtn(
            icon: HugeIcons.solidStandardStackStar, // Your icon
            onPressed: () {
              final currentPage = ref.read(currentPageProvider) + 1; // 1-based page
              final quranInfoService = ref.read(quranInfoServiceProvider); // Read the service provider

              final page = currentPage;
              final sura = quranInfoService.getSuraByPage(page); // Get a representative Sura for the page
              final para = quranInfoService.getParaByPage(page); // Get Para for the page

              // Consider using 'page-${page}' as identifier for uniqueness
              final identifier = 'page-$page'; // Unique identifier for page bookmark

              // Ensure sura and para are found before creating bookmark
              if (sura != null && para != null) {
                final bookmark = Bookmark(
                  type: 'page',
                  identifier: identifier,
                  sura: sura, // Store representative Sura
                  para: para, // Store Para
                  page: page, // Store Page
                  // ayah is null for page bookmarks
                );

                ref.read(bookmarkProvider.notifier).add(bookmark);
              } else {
                // Handle case where sura or para could not be determined for the page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not determine Sura/Para for this page')),
                );
              }
            },
          ),
          _iconBtn(icon: HugeIcons.solidRoundedArrowExpand, onPressed: (){})
          // _iconBtn(
          //   icon: drawerOpen
          //       ? Icons.keyboard_arrow_left
          //       : Icons.keyboard_arrow_right,
          //   onPressed: () {
          //     if (drawerOpen) {
          //       Navigator.of(context).pop();
          //     } else {
          //       rootKey.currentState?.openDrawer();
          //     }
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onPressed,
    double? size,
    Color color = Colors.white,
  }) {
    return IconButton(
      iconSize: size ?? 28,
      constraints: const BoxConstraints(minHeight: 64, minWidth: 48),
      padding: EdgeInsets.zero,
      icon: Center(child: Icon(icon, color: color)),
      onPressed: onPressed,
    );
  }
}




