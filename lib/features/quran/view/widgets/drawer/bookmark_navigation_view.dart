import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import screenutil
import '../../../../../core/theme.dart'; // Assuming primaryColor is defined here
import '../../../viewmodel/ayah_highlight_viewmodel.dart';
import '../../../viewmodel/bookmark_viewmodel.dart';

class BookmarkNavigationView extends ConsumerWidget {
  const BookmarkNavigationView({super.key});

  // Helper function to convert Latin numbers to Bengali numbers (Keep this)
  String toBengaliNumber(int number) {
    const latinNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
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

    return DefaultTabController(
      length: 2,
      child: bookmarksAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Text(
            'Error loading bookmarks: ${e.toString()}\n$s',
            style: TextStyle(fontSize: 14.sp), // Scale text
          ),
        ),
        data: (bookmarks) {
          final ayahBookmarks = bookmarks
              .where((b) => b.type == 'ayah')
              .toList();
          final pageBookmarks = bookmarks
              .where((b) => b.type == 'page')
              .toList();

          return Column(
            children: [
              // --- TabBar Styling (Matching SideDrawer's main TabBar) ---
              Container(
                color:  const Color(0xFF1B5E20), // Light green background
                child: TabBar(
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white,
                  indicator: BoxDecoration(
                    color: const Color(0xFF144910) ,
                    borderRadius: BorderRadius.zero,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 0.0,
                  tabs: [
                    Tab(child: Text('আয়াত', style: TextStyle(fontSize: 14.sp, color: Colors.white))),
                    Tab(child: Text('পৃষ্ঠা', style: TextStyle(fontSize: 14.sp, color: Colors.white))),
                  ],
                ),
              ),
              // --- End TabBar Styling ---
              Expanded(
                child: TabBarView(
                  children: [
                    // Ayah Bookmarks List
                    ayahBookmarks.isEmpty
                        ? Center(child: Text(
                      'কোনো আয়াত বুকমার্ক করা নেই।', // Message when empty
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                    ))
                        : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: ayahBookmarks.length,
                      separatorBuilder: (context, index) => Divider(height: 1.h, color: Colors.grey.shade300),
                      itemBuilder: (_, i) {
                        final b = ayahBookmarks[i];
                        final suraName = (b.sura != null && b.sura! > 0 && b.sura! <= suraNames.length)
                            ? suraNames[b.sura! - 1]
                            : 'Unknown Sura';

                        Widget listTileContent;
                        if (b.sura != null && b.ayah != null && b.para != null && b.page != null) {
                          listTileContent = Row( // Use a Row here
                            crossAxisAlignment: CrossAxisAlignment.center, // Vertically center items in the Row
                            children: [
                              // Bookmark Number (Vertically Centered)
                              Text(
                                '${toBengaliNumber(i + 1)}.',
                                style: TextStyle(
                                  fontSize: 14.sp, // Scaled font size
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor, // Example: using primary color
                                ),
                              ),
                              SizedBox(width: 8.w), // Scaled spacing between number and text column
                              // Text Content (Column)
                              Expanded( // Let the Column take remaining space
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center, // Vertically center the Column content
                                  crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
                                  children: [
                                    // --- Ayah Bookmark Line 1 ---
                                    Text(
                                      '$suraName, আয়াত ${toBengaliNumber(b.ayah!)}', // Sura Name, Ayah label, Ayah number
                                      style: TextStyle(
                                        fontSize: 12.sp, // Scaled font size
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade800, // Darker grey
                                      ),
                                    ),
                                    // --- Ayah Bookmark Line 2 ---
                                    SizedBox(height: 2.h), // Scaled spacing
                                    Text(
                                      'পারা ${toBengaliNumber(b.para!)}, পৃষ্ঠা ${toBengaliNumber(b.page!)}', // Para label, Para number, Page label, Page number
                                      style: TextStyle(
                                        fontSize: 12.sp, // Scaled font size
                                        color: Colors.grey.shade600, // Lighter grey
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          listTileContent = Text( // Fallback for incomplete data
                            'Bookmark ID: ${b.identifier} (Data incomplete)',
                            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                          );
                        }


                        return ListTile(
                          title: listTileContent, // Use the formatted content as title
                          // Removed subtitle
                          onTap: () {
                            if (b.sura != null && b.ayah != null && b.page != null) {
                              try {
                                final sura = b.sura!;
                                final ayah = b.ayah!;
                                final targetPage = b.page!;
                                ref.read(navigateToPageCommandProvider.notifier).state = targetPage;
                                ref.read(selectedAyahProvider.notifier).selectByNavigation(sura, ayah);
                                Navigator.of(context).pop();
                              } catch (e) {
                                debugPrint('Error during ayah bookmark navigation: $e');
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not navigate to bookmark', style: TextStyle(fontSize: 14.sp))));
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bookmark data incomplete. Cannot navigate.', style: TextStyle(fontSize: 14.sp))));
                            }
                          },
                          trailing: IconButton(
                              icon: Icon(Icons.delete, size: 20.r, color: Colors.grey.shade600),
                              onPressed: () {
                                ref.read(bookmarkProvider.notifier).remove(b.identifier);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bookmark removed', style: TextStyle(fontSize: 14.sp))));
                              }
                          ),
                          // Added vertical padding for the entire ListTile
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          // Min height adjustments for ListTiles with custom content
                          minVerticalPadding: 0,
                          visualDensity: VisualDensity.compact,
                        );
                      },
                    ),
                    // Page Bookmarks List
                    pageBookmarks.isEmpty
                        ? Center(child: Text(
                      'কোনো পৃষ্ঠা বুকমার্ক করা নেই।', // Message when empty
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                    ))
                        : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: pageBookmarks.length,
                      separatorBuilder: (context, index) => Divider(height: 1.h, color: Colors.grey.shade300),
                      itemBuilder: (_, i) {
                        final b = pageBookmarks[i];
                        final suraName = (b.sura != null && b.sura! > 0 && b.sura! <= suraNames.length)
                            ? suraNames[b.sura! - 1]
                            : 'Unknown Sura';

                        Widget listTileContent;
                        if (b.page != null && b.sura != null && b.para != null) {
                          listTileContent = Row( // Use a Row here
                            crossAxisAlignment: CrossAxisAlignment.center, // Vertically center items in the Row
                            children: [
                              // Bookmark Number (Vertically Centered)
                              Text(
                                '${toBengaliNumber(i + 1)}.',
                                style: TextStyle(
                                  fontSize: 14.sp, // Scaled font size
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor, // Example: using primary color
                                ),
                              ),
                              SizedBox(width: 8.w), // Scaled spacing between number and text column
                              // Text Content (Column)
                              Expanded( // Let the Column take remaining space
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center, // Vertically center the Column content
                                  crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
                                  children: [
                                    // --- Page Bookmark Line 1 ---
                                    Text(
                                      suraName, // Just Sura name on the first line for Page bookmarks
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    // --- Page Bookmark Line 2 ---
                                    SizedBox(height: 2.h), // Scaled spacing
                                    Text(
                                      'পারা ${toBengaliNumber(b.para!)}, পৃষ্ঠা ${toBengaliNumber(b.page!)}', // Para label, Para number, Page label, Page number
                                      style: TextStyle(
                                        fontSize: 12.sp, // Scaled font size
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          listTileContent = Text( // Fallback for incomplete data
                            'Bookmark ID: ${b.identifier} (Data incomplete)',
                            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                          );
                        }


                        return ListTile(
                          title: listTileContent, // Use the formatted content as title
                          // Removed subtitle
                          onTap: () {
                            if (b.page != null) {
                              try {
                                final page = b.page!;
                                ref.read(navigateToPageCommandProvider.notifier).state = page;
                                ref.read(selectedAyahProvider.notifier).clear();
                                Navigator.of(context).pop();
                              } catch (e) {
                                debugPrint('Error during page bookmark navigation: $e');
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not navigate to bookmark', style: TextStyle(fontSize: 14.sp))));
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bookmark data incomplete. Cannot navigate.', style: TextStyle(fontSize: 14.sp))));
                            }
                          },
                          trailing: IconButton(
                              icon: Icon(Icons.delete, size: 24.r, color: Colors.grey.shade600),
                              onPressed: () {
                                ref.read(bookmarkProvider.notifier).remove(b.identifier);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bookmark removed', style: TextStyle(fontSize: 14.sp))));
                              }
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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