import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          final double topInset = kToolbarHeight + media.padding.top;
          final double bottomInset = bottomBarHeight + media.padding.bottom;

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
            padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
            child: SizedBox(
              width: 250,
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
                      // ... Your TabBar remains the same ...
                      Container(
                        color: const Color(0xFFB2FF59), // Light green
                        child: const TabBar( // Added const as children are constant
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.black87,
                          indicator: BoxDecoration(
                            color: Color(0xFF1B5E20), // Full dark green for active tab
                            borderRadius: BorderRadius.zero,
                          ),
                          indicatorSize: TabBarIndicatorSize.tab, // Fills the whole tab
                          tabs: [
                            Tab(text: 'সূরা'),
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


