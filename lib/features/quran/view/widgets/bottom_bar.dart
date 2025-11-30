import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../model/bookmark.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart';
import '../../viewmodel/bookmark_viewmodel.dart';
import '../../viewmodel/reciter_providers.dart';
import 'audio_bottom_sheet.dart';
import '../../../../../core/theme.dart';

class BottomBar extends ConsumerWidget {
  final bool drawerOpen;
  final GlobalKey<ScaffoldState> rootKey;

  const BottomBar({super.key, required this.drawerOpen, required this.rootKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedReciter = ref.watch(selectedReciterProvider);
    final displayReciterName =
        reciters.entries.firstWhere((e) => e.value == selectedReciter).key;

    final currentPage = ref.watch(currentPageProvider) + 1;
    final bookmarkNotifier = ref.read(bookmarkProvider.notifier);
    final bookmarksAsync = ref.watch(bookmarkProvider);

    final bool isPageBookmarked =
        bookmarkNotifier.isPageBookmarked(currentPage);

    return Container(
      height: bottomBarHeight.h,
      color: const Color(0xFF294B39),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _iconBtn(
            icon: HugeIcons.strokeRoundedPlay,
            onPressed: () {
              final sura = ref.watch(currentSuraProvider);
              final page = ref.watch(currentPageProvider);

              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return AudioBottomSheet(
                      currentSura: ref.read(currentSuraProvider));
                },
              );
            },
          ),
          Expanded(
            child: Container(
              height: 40.h,
              margin: EdgeInsets.symmetric(vertical: 12.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: const Color(0xFF294B39),
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: const Color(0xFF294B39),
                  iconEnabledColor: Colors.white,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                  value: displayReciterName,
                  items: reciters.keys.map((displayName) {
                    return DropdownMenuItem(
                      value: displayName,
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
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
          SizedBox(width: 5.w),
          Consumer(
            builder: (_, ref, __) {
              final on = ref.watch(touchModeProvider);
              return _iconBtn(
                icon: HugeIcons.strokeRoundedTouchLocked03,
                color: on ? Colors.orangeAccent : Colors.white,
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
            icon: HugeIcons.strokeRoundedScreenRotation,
            size: 24.r,
            onPressed: () => OrientationToggle.toggle(),
          ),
          _iconBtn(
            icon: isPageBookmarked
                ? HugeIcons.strokeRoundedStarOff
                : HugeIcons.strokeRoundedStar,
            color: isPageBookmarked ? Colors.orangeAccent : Colors.white,
            size: 24.r,
            onPressed: () {
              if (!context.mounted) return;

              final pageToBookmark = ref.read(currentPageProvider) + 1;
              final identifier = 'page-$pageToBookmark';

              if (isPageBookmarked) {
                bookmarkNotifier.remove(identifier);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                    'পৃষ্ঠা বুকমার্ক থেকে সরানো হয়েছে',
                    style: TextStyle(fontSize: 14.sp),
                  )),
                );
              } else {
                final quranInfoService = ref.read(quranInfoServiceProvider);

                final sura = quranInfoService.getSuraByPage(pageToBookmark);
                final para = quranInfoService.getParaByPage(pageToBookmark);

                if (sura != null && para != null) {
                  final bookmark = Bookmark(
                    type: 'page',
                    identifier: identifier,
                    sura: sura,
                    para: para,
                    page: pageToBookmark,
                  );

                  bookmarkNotifier.add(bookmark);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                      'পৃষ্ঠা বুকমার্ক করা হয়েছে',
                      style: TextStyle(fontSize: 14.sp),
                    )),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                      'এই পৃষ্ঠার জন্য সূরা/পারা নির্ধারণ করা যায়নি',
                      style: TextStyle(fontSize: 14.sp),
                    )),
                  );
                }
              }
            },
          ),
          _iconBtn(
            icon: HugeIcons.strokeRoundedNavigation05,
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
      iconSize: size ?? 24.r,
      constraints: BoxConstraints(minHeight: 64.h, minWidth: 48.w),
      padding: EdgeInsets.zero,
      icon: Center(child: HugeIcon(icon: icon, color: color)),
      onPressed: onPressed,
    );
  }
}
