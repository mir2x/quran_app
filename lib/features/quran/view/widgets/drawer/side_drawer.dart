import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran_app/features/quran/view/widgets/drawer/bookmark_navigation_view.dart';
import 'package:quran_app/features/quran/view/widgets/drawer/para_navigation_view.dart';
import 'package:quran_app/features/quran/view/widgets/drawer/sura_navigation_view.dart';
import '../../../../../core/theme.dart';
import '../../../viewmodel/ayah_highlight_viewmodel.dart';

class SideDrawer extends ConsumerWidget {
  const SideDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.topLeft,
      child: Builder(
        builder: (context) {
          final media = MediaQuery.of(context);
          // These calculations remain based on system UI elements and safe areas,
          // not directly scaled by ScreenUtil, but their final rendered size
          // will be part of the overall scaled layout.
          final double topInset = kToolbarHeight + media.padding.top;
          final double bottomInset = bottomBarHeight.h + media.padding.bottom;

          // Watch the data needed for the drawer views
          final suraMapping = ref.watch(suraPageMappingProvider);
          final paraMapping = ref.watch(paraPageMappingProvider);
          final ayahMapping = ref.watch(ayahPageMappingProvider);
          final ayahCounts = ref.watch(ayahCountsProvider);
          final suraNames = ref.watch(suraNamesProvider); // Get sura names
          final paraPageRanges = ref.watch(paraPageRangesProvider); // Watch the new provider

          // Check if main data (allBoxesProvider, totalPageCountProvider, and mappings) is still loading or has error
          final allBoxesAsync = ref.watch(allBoxesProvider);
          final totalPageCountAsync = ref.watch(totalPageCountProvider);

          final bool isLoading = allBoxesAsync.isLoading || totalPageCountAsync.isLoading;
          final bool hasError = allBoxesAsync.hasError || totalPageCountAsync.hasError;

          // Also check if necessary mappings are loaded when data is available
          final bool isDataReady = !isLoading && !hasError &&
              suraMapping.isNotEmpty &&
              paraMapping.isNotEmpty &&
              ayahMapping.isNotEmpty &&
              paraPageRanges.isNotEmpty;


          Widget tabContent; // Widget to place inside the TabBarView
          if (isLoading) {
            tabContent = const Center(child: CircularProgressIndicator());
          } else if (hasError) {
            // Display specific error if needed
            final errorText = allBoxesAsync.hasError ? allBoxesAsync.error.toString() : totalPageCountAsync.error.toString();
            tabContent = Center(child: Text('Error loading data:\n$errorText'));
          } else if (!isDataReady) {
            // Data might be loaded but mappings still being processed or unexpectedly empty
            tabContent = const Center(child: Text('Processing data...'));
          }
          else {
            // Data and mappings are ready, build the tab views
            tabContent = TabBarView(
              children: [
                const SurahNavigationView(),
                const ParaNavigationView(),
                const BookmarkNavigationView(),
              ],
            );
          }

          return Padding(
            // Padding based on system UI elements remains as is.
            padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
            child: SizedBox(
              // Use screenutil for the drawer width
              width: 250.w,
              child: Material(
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      Expanded(
                        // Use the content determined above
                        child: tabContent, // Use tabContent here
                      ),
                      // The TabBar height is usually determined by its content and theme,
                      // but text size and spacing within it can be scaled.
                      Container(
                        color: const Color(0xFFB2FF59), // Light green
                        child: TabBar( // Removed const as Tab(text:) uses .sp
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.black87,
                          indicator: const BoxDecoration( // Kept const as decoration values are const
                            color: Color(0xFF1B5E20), // Full dark green for active tab
                            borderRadius: BorderRadius.zero,
                          ),
                          indicatorSize: TabBarIndicatorSize.tab, // Fills the whole tab
                          tabs: [
                            Tab(text: 'সূরা'), // Text widget within Tab will be scaled if using .sp
                            Tab(text: 'পারা'),
                            Tab(text: 'বুকমার্ক'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}