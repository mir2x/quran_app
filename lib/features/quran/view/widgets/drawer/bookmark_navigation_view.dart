import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../viewmodel/ayah_highlight_viewmodel.dart';
import '../../../viewmodel/bookmark_viewmodel.dart';

class BookmarkNavigationView extends ConsumerWidget {
  const BookmarkNavigationView({super.key});

  String toBengaliNumber(int number) {
    const bengaliNumbers = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    String numberStr = number.toString();
    String bengaliStr = '';
    for (int i = 0; i < numberStr.length; i++) {
      int digit = int.parse(numberStr[i]);
      bengaliStr += bengaliNumbers[digit];
    }
    return bengaliStr;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkProvider);
    final suraNames = ref.watch(suraNamesProvider);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final tabFontSize = isLandscape ? 12.0 : 14.sp;
    final listTileTitleFontSize = isLandscape ? 12.0 : 14.sp;
    final listTileSubtitleFontSize = isLandscape ? 10.0 : 12.sp;

    return DefaultTabController(
      length: 2,
      child: bookmarksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Text(
            'Error loading bookmarks: ${e.toString()}\n$s',
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
        data: (bookmarks) {
          final ayahBookmarks =
              bookmarks.where((b) => b.type == 'ayah').toList();
          final pageBookmarks =
              bookmarks.where((b) => b.type == 'page').toList();

          return Column(
            children: [
              Container(
                color: const Color(0xFF1B5E20),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white,
                  indicator: const BoxDecoration(
                    color: Color(0xFF144910),
                    borderRadius: BorderRadius.zero,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 0.0,
                  tabs: [
                    Tab(
                      child: Text(
                        'আয়াত',
                        style: TextStyle(
                            fontSize: tabFontSize, color: Colors.white),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'পৃষ্ঠা',
                        style: TextStyle(
                            fontSize: tabFontSize, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ayahBookmarks.isEmpty
                        ? Center(
                            child: Text(
                              'কোনো আয়াত বুকমার্ক করা নেই।',
                              style: TextStyle(
                                  fontSize: 14.sp, color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: ayahBookmarks.length,
                            separatorBuilder: (context, index) => Divider(
                                height: 1.h, color: Colors.grey.shade300),
                            itemBuilder: (_, i) {
                              final b = ayahBookmarks[i];
                              final suraName = (b.sura != null &&
                                      b.sura! > 0 &&
                                      b.sura! <= suraNames.length)
                                  ? suraNames[b.sura! - 1]
                                  : 'Unknown Sura';

                              Widget listTileContent;
                              if (b.sura != null &&
                                  b.ayah != null &&
                                  b.para != null &&
                                  b.page != null) {
                                listTileContent = Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${toBengaliNumber(i + 1)}.',
                                      style: TextStyle(
                                        fontSize: listTileTitleFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$suraName, আয়াত ${toBengaliNumber(b.ayah!)}',
                                            style: TextStyle(
                                              fontSize:
                                                  listTileSubtitleFontSize,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            'পারা ${toBengaliNumber(b.para!)}, পৃষ্ঠা ${toBengaliNumber(b.page!)}',
                                            style: TextStyle(
                                              fontSize:
                                                  listTileSubtitleFontSize,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                listTileContent = Text(
                                  'Bookmark ID: ${b.identifier} (Data incomplete)',
                                  style: TextStyle(
                                      fontSize: listTileTitleFontSize,
                                      color: Colors.grey.shade600),
                                );
                              }

                              return ListTile(
                                title: listTileContent,
                                onTap: () {
                                  if (b.sura != null &&
                                      b.ayah != null &&
                                      b.page != null) {
                                    try {
                                      final sura = b.sura!;
                                      final ayah = b.ayah!;
                                      final targetPage = b.page!;
                                      // Select Ayah FIRST
                                      ref
                                          .read(selectedAyahProvider.notifier)
                                          .selectByNavigation(sura, ayah);
                                      // THEN Navigate
                                      ref
                                          .read(navigateToPageCommandProvider
                                              .notifier)
                                          .state = targetPage;
                                      Navigator.of(context).pop();
                                    } catch (e) {
                                      debugPrint(
                                          'Error during ayah bookmark navigation: $e');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not navigate to bookmark',
                                            style: TextStyle(fontSize: 14.sp),
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Bookmark data incomplete. Cannot navigate.',
                                                style: TextStyle(
                                                    fontSize: 14.sp))));
                                  }
                                },
                                trailing: IconButton(
                                    icon: Icon(Icons.delete,
                                        size: 20.r,
                                        color: Colors.grey.shade600),
                                    onPressed: () {
                                      ref
                                          .read(bookmarkProvider.notifier)
                                          .remove(b.identifier);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Bookmark removed',
                                            style: TextStyle(fontSize: 14.sp),
                                          ),
                                        ),
                                      );
                                    }),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 8.h),
                                minVerticalPadding: 0,
                                visualDensity: VisualDensity.compact,
                              );
                            },
                          ),
                    pageBookmarks.isEmpty
                        ? Center(
                            child: Text(
                              'কোনো পৃষ্ঠা বুকমার্ক করা নেই।',
                              style: TextStyle(
                                  fontSize: 14.sp, color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: pageBookmarks.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1.h,
                              color: Colors.grey.shade300,
                            ),
                            itemBuilder: (_, i) {
                              final b = pageBookmarks[i];
                              final suraName = (b.sura != null &&
                                      b.sura! > 0 &&
                                      b.sura! <= suraNames.length)
                                  ? suraNames[b.sura! - 1]
                                  : 'Unknown Sura';

                              Widget listTileContent;
                              if (b.page != null &&
                                  b.sura != null &&
                                  b.para != null) {
                                listTileContent = Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${toBengaliNumber(i + 1)}.',
                                      style: TextStyle(
                                        fontSize: listTileTitleFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            suraName,
                                            style: TextStyle(
                                              fontSize:
                                                  listTileSubtitleFontSize,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            'পারা ${toBengaliNumber(b.para!)}, পৃষ্ঠা ${toBengaliNumber(b.page!)}',
                                            style: TextStyle(
                                              fontSize:
                                                  listTileSubtitleFontSize,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                listTileContent = Text(
                                  'Bookmark ID: ${b.identifier} (Data incomplete)',
                                  style: TextStyle(
                                      fontSize: listTileTitleFontSize,
                                      color: Colors.grey.shade600),
                                );
                              }

                              return ListTile(
                                title: listTileContent,
                                onTap: () {
                                  if (b.page != null) {
                                    try {
                                      final page = b.page!;
                                      // Clear selection FIRST
                                      ref
                                          .read(selectedAyahProvider.notifier)
                                          .clear();
                                      // THEN Navigate
                                      ref
                                          .read(navigateToPageCommandProvider
                                              .notifier)
                                          .state = page;
                                      Navigator.of(context).pop();
                                    } catch (e) {
                                      debugPrint(
                                          'Error during page bookmark navigation: $e');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not navigate to bookmark',
                                            style: TextStyle(fontSize: 14.sp),
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Bookmark data incomplete. Cannot navigate.',
                                          style: TextStyle(fontSize: 14.sp),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                trailing: IconButton(
                                  icon: Icon(Icons.delete,
                                      size: 24.r, color: Colors.grey.shade600),
                                  onPressed: () {
                                    ref
                                        .read(bookmarkProvider.notifier)
                                        .remove(b.identifier);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Bookmark removed',
                                          style: TextStyle(fontSize: 14.sp),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                                minVerticalPadding: 0,
                                visualDensity: VisualDensity.compact,
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
