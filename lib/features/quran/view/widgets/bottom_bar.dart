import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import screenutil
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:hugeicons/hugeicons.dart';
import '../../model/bookmark.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart';
import '../../viewmodel/bookmark_viewmodel.dart';
import 'audio_bottom_sheet.dart';
import '../../../../../core/theme.dart';

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

    final currentPage = ref.watch(currentPageProvider) + 1;
    final bookmarkNotifier = ref.read(bookmarkProvider.notifier);
    final bookmarksAsync = ref.watch(bookmarkProvider);


    final bool isPageBookmarked = bookmarkNotifier.isPageBookmarked(currentPage);

    return Container( // Changed from BottomAppBar
      // Scale height using .h
      height: bottomBarHeight.h, // Set the desired height
      color: const Color(0xFF294B39), // Set the background color
      // Remove padding here, let the Row manage its internal spacing
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _iconBtn(
            icon: HugeIcons.solidRoundedPlay,
            onPressed: () {

              final sura = ref.watch(currentSuraProvider);
              final page = ref.watch(currentPageProvider);


              showModalBottomSheet(
                context: context,
                // Ensure the bottom sheet is responsive
                // The content inside AudioBottomSheet will use ScreenUtil.
                builder: (BuildContext context) {

                  return AudioBottomSheet(currentSura: ref.read(currentSuraProvider));
                },

              );
            },
          ),

          Expanded(
            child: Container(
              // Scale height using .h
              height: 40.h,
              // Scale margin using .h and .w
              margin: EdgeInsets.symmetric(vertical: 12.h),
              // Scale padding using .w
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: const Color(0xFF294B39),
                border: Border.all(color: Colors.white24),
                // Scale border radius using .r
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: const Color(0xFF294B39),
                  iconEnabledColor: Colors.white,
                  style: TextStyle(color: Colors.white,
                    // Scale font size using .sp
                    fontSize: 14.sp, // Example size
                  ),
                  value: displayReciterName,
                  items: reciters.keys.map((displayName) {
                    return DropdownMenuItem(
                      value: displayName,
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white,
                          // Scale font size using .sp
                          fontSize: 14.sp, // Example size
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      // Ensure selectedReciterProvider is accessible
                      ref.read(selectedReciterProvider.notifier).state =
                      reciters[val]!;
                    }
                  },
                ),
              ),
            ),
          ),
          // Scale width using .w
          SizedBox(width: 5.w),
          Consumer(
            builder: (_, ref, __) {
              final on = ref.watch(touchModeProvider);
              return _iconBtn(
                icon: HugeIcons.solidStandardTouchLocked04,
                color: on ? Colors.orangeAccent : Colors.white,
                // Scale size using .r
                size: 26.r,
                onPressed: () {
                  ref.read(touchModeProvider.notifier).toggle();
                  if (!ref.read(touchModeProvider)) {
                    ref.read(selectedAyahProvider.notifier).clear();
                  }
                },
              );
            },
          ),
          _iconBtn(
            icon: HugeIcons.solidSharpScreenRotation,
            // Scale size using .r
            size: 24.r,
            onPressed: () => OrientationToggle.toggle(),
          ),
          // Bookmark Button (Enhanced)
          _iconBtn(
            icon: isPageBookmarked ? HugeIcons.solidStandardStackStar : HugeIcons.strokeStandardStackStar,
            color: isPageBookmarked ? Colors.orangeAccent : Colors.white,
            // Scale size using .r
            size: 24.r,
            onPressed: () {
              if (!context.mounted) return;

              final pageToBookmark = ref.read(currentPageProvider) + 1;
              final identifier = 'page-$pageToBookmark';

              if (isPageBookmarked) {
                // Remove bookmark
                bookmarkNotifier.remove(identifier);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                        'পৃষ্ঠা বুকমার্ক থেকে সরানো হয়েছে',
                        style: TextStyle(fontSize: 14.sp), // Scale text
                      )),
                );
              } else {

                final quranInfoService = ref.read(quranInfoServiceProvider);

                final sura = quranInfoService.getSuraByPage(pageToBookmark);
                final para = quranInfoService.getParaByPage(pageToBookmark);

                // Ensure sura and para are found before creating bookmark
                if (sura != null && para != null) {
                  final bookmark = Bookmark(
                    type: 'page', // Assuming Bookmark type is 'page'
                    identifier: identifier,
                    sura: sura, // Store representative Sura
                    para: para, // Store Para
                    page: pageToBookmark, // Store Page
                    // ayah is null for page bookmarks
                  );

                  bookmarkNotifier.add(bookmark);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                          'পৃষ্ঠা বুকমার্ক করা হয়েছে',
                          style: TextStyle(fontSize: 14.sp), // Scale text
                        )),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                          'এই পৃষ্ঠার জন্য সূরা/পারা নির্ধারণ করা যায়নি',
                          style: TextStyle(fontSize: 14.sp), // Scale text
                        )),
                  );
                }
              }
            },
          ),
          _iconBtn(
            icon: HugeIcons.solidRoundedNavigation01,
            // Scale size using .r
            size: 24.r,
            onPressed: () {
              if (drawerOpen) {
                rootKey.currentState?.closeDrawer();
              } else {
                rootKey.currentState?.openDrawer();
              }
            },
          ),
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
      // Scale icon size using .r, fallback to a scaled default if size is null
      iconSize: size ?? 24.r,
      // Scale constraints using .h and .w
      constraints: BoxConstraints(minHeight: 64.h, minWidth: 48.w),
      // Padding is zero, no scaling needed
      padding: EdgeInsets.zero,
      icon: Center(child: Icon(icon, color: color)),
      onPressed: onPressed,
    );
  }
}