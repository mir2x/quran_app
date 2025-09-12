import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran_app/features/quran/view/widgets/drawer/bookmark_navigation_view.dart';
import 'package:quran_app/features/quran/view/widgets/drawer/para_navigation_view.dart';
import 'package:quran_app/features/quran/view/widgets/drawer/sura_navigation_view.dart';
import '../../../../../core/theme.dart';
import '../../../viewmodel/ayah_highlight_viewmodel.dart';

// --- NEW State Provider for the active tab index ---
final drawerTabIndexProvider = StateProvider<int>((_) => 0); // Default to the first tab (Surah)

class SideDrawer extends ConsumerStatefulWidget {
  const SideDrawer({super.key});

  @override
  ConsumerState<SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends ConsumerState<SideDrawer> with SingleTickerProviderStateMixin {
  // --- NEW: TabController to control the TabBar ---
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize the TabController and set its initial index from our provider.
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: ref.read(drawerTabIndexProvider), // Read the last saved index
    );

    // Add a listener to the controller. When the user swipes or taps a tab,
    // this listener will update our Riverpod state provider.
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        ref.read(drawerTabIndexProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- The rest of your build logic is almost identical ---
    return Align(
      alignment: Alignment.topLeft,
      child: Builder(
        builder: (context) {
          final media = MediaQuery.of(context);
          final double topInset = kToolbarHeight + media.padding.top;
          final double bottomInset = bottomBarHeight.h + media.padding.bottom;

          // Data loading checks remain the same
          final allBoxesAsync = ref.watch(allBoxesProvider);
          final totalPageCountAsync = ref.watch(totalPageCountProvider);
          final suraMapping = ref.watch(suraPageMappingProvider);
          final paraPageRanges = ref.watch(paraPageRangesProvider);

          final bool isLoading = allBoxesAsync.isLoading || totalPageCountAsync.isLoading;
          final bool hasError = allBoxesAsync.hasError || totalPageCountAsync.hasError;
          final bool isDataReady = !isLoading && !hasError && suraMapping.isNotEmpty && paraPageRanges.isNotEmpty;

          Widget tabContent;
          if (isLoading) {
            tabContent = const Center(child: CircularProgressIndicator());
          } else if (hasError) {
            tabContent = const Center(child: Text('Error loading data'));
          } else if (!isDataReady) {
            tabContent = const Center(child: Text('Processing data...'));
          } else {
            // --- CHANGE: Pass the controller to TabBarView ---
            tabContent = TabBarView(
              controller: _tabController, // Connect the controller
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
              width: 250.w,
              child: Material(
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                // --- REMOVED: DefaultTabController is no longer needed ---
                child: Column(
                  children: [
                    Expanded(
                      child: tabContent,
                    ),
                    Container(
                      color: const Color(0xFF1B5E20),
                      // --- CHANGE: Pass the controller to TabBar ---
                      child: TabBar(
                        controller: _tabController, // Connect the controller
                        labelColor: Colors.white,
                        dividerColor: Colors.transparent,
                        unselectedLabelColor: Colors.white,
                        indicator: const BoxDecoration(
                          color: Color(0xFF144910),
                          borderRadius: BorderRadius.zero,
                        ),
                        indicatorWeight: 0,
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: const [
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
          );
        },
      ),
    );
  }
}