import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/quran/view/widgets/audio_control_bar.dart';
import 'package:quran_app/features/quran/view/widgets/bottom_bar.dart';
import 'package:quran_app/features/quran/view/widgets/drawer/side_drawer.dart';
import '../../../../core/theme.dart';
import 'widgets/quran_page.dart';
import '../viewmodel/ayah_highlight_viewmodel.dart';

class QuranViewerScreen extends ConsumerStatefulWidget {
  final Directory editionDir;
  final int imageWidth;
  final int imageHeight;
  final String imageExt;

  const QuranViewerScreen({
    super.key,
    required this.editionDir,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageExt,
  });

  @override
  ConsumerState<QuranViewerScreen> createState() => _QuranViewerState();
}

class _QuranViewerState extends ConsumerState<QuranViewerScreen> {
  final _rootKey = GlobalKey<ScaffoldState>();

  PageController? _portraitCtrl;
  ScrollController? _landscapeCtrl;

  Orientation? _lastOri;

  late final Future<int> _pageCountF;

  double get _aspect => widget.imageWidth / widget.imageHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editionConfigProvider.notifier).set(EditionConfig(
        dir: widget.editionDir,
        imageWidth: widget.imageWidth,
        imageHeight: widget.imageHeight,
        imageExt: widget.imageExt,
      ));
    });
  }


  @override
  void dispose() {
    _portraitCtrl?.dispose();
    _landscapeCtrl?.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    leading: Builder(
      builder: (ctx) => IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => Scaffold.of(ctx).openDrawer(),
      ),
    ),
    title: const Text(
      'কুরআন মজীদ',
      style: TextStyle(fontFamily: 'SolaimanLipi', fontSize: 22),
    ),
    centerTitle: true,
    actions: [
      IconButton(icon: const Icon(Icons.search), onPressed: () {}),
      IconButton(icon: const Icon(Icons.nightlight_outlined), onPressed: () {}),
      IconButton(icon: const Icon(Icons.g_translate), onPressed: () {}),
    ],
  );

  // Inside _QuranViewerState class

  Widget _buildSideDrawer() {
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
                // Surah tab view
                _buildSurahAyahTabView(suraMapping, ayahCounts, suraNames, ayahMapping),
                // Para tab view - pass the page ranges
                _buildParaTabView(paraPageRanges),
                // Bookmark tab view
                _buildBookmarkTabView(),
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

  // Keep _buildSurahAyahTabView as is (updated in previous step)
  // Keep _buildBookmarkTabView as is

  // Remove the old _buildParaListTabView method as it's replaced by _buildParaTabView, _buildParaList, and _buildParaPageList
  // Widget _buildParaListTabView(Map<int, int> paraMapping) { ... } // Remove this method

  Widget _buildSurahAyahTabView(
      Map<int, int> suraMapping,
      List<int> ayahCounts,
      List<String> suraNames,
      Map<(int, int), int> ayahPageMapping,
      ) {
    final selectedSurah = ref.watch(selectedNavigationSurahProvider);

    if (selectedSurah == null) {
      // Show list of all Surahs
      return _buildSurahList(suraMapping, ayahCounts, suraNames);
    } else {
      // Show list of Ayahs for the selected Surah
      return _buildAyahListForSurah(selectedSurah, ayahCounts, suraNames, ayahPageMapping);
    }
  }

  Widget _buildSurahList(Map<int, int> suraMapping, List<int> ayahCounts, List<String> suraNames) {
    if (suraNames.length < 114 || ayahCounts.length < 114 || suraMapping.isEmpty) {
      return const Center(child: Text('Data incomplete.'));
    }

    return ListView.builder(
      itemCount: 114,
      itemBuilder: (context, index) {
        final suraNumber = index + 1;
        final startPage = suraMapping[suraNumber];
        final totalAyahs = ayahCounts[index];
        final surahName = suraNames[index];

        return ListTile(
          title: Text('$suraNumber. $surahName'),
          subtitle: Text('আয়াত: $totalAyahs, পৃষ্ঠা: ${startPage ?? 'N/A'}'),
          onTap: () {
            // Select this surah to show its ayahs
            ref.read(selectedNavigationSurahProvider.notifier).state = suraNumber;
          },
        );
      },
    );
  }

  Widget _buildAyahListForSurah(int suraNumber, List<int> ayahCounts, List<String> suraNames, Map<(int, int), int> ayahPageMapping) {
    if (suraNumber < 1 || suraNumber > 114) {
      return const Center(child: Text('Invalid Surah number selected.'));
    }

    final totalAyahs = ayahCounts[suraNumber - 1]; // Ayah counts list is 0-indexed

    return Column(
      children: [
        // Add a "Back" button at the top
        ListTile(
          leading: const Icon(Icons.arrow_back),
          title: Text('সব সূরা দেখুন'),
          onTap: () {
            // Go back to the list of all surahs
            ref.read(selectedNavigationSurahProvider.notifier).state = null;
          },
        ),
        const Divider(height: 1), // Optional divider

        Expanded(
          child: ListView.builder(
            itemCount: totalAyahs,
            itemBuilder: (context, index) {
              final ayahNumber = index + 1;
              // Get the page number for this specific Ayah
              final targetPage = ayahPageMapping[(suraNumber, ayahNumber)];

              return ListTile(
                title: Text('আয়াত $ayahNumber'),
                trailing: targetPage != null ? Text('পৃষ্ঠা $targetPage') : const Text('N/A'),
                onTap: () {
                  if (targetPage != null) {
                    // Navigate to the page
                    ref.read(navigateToPageCommandProvider.notifier).state = targetPage;
                    // Update the selected ayah provider for highlighting
                    // We set Rect.zero initially, QuranPage will calculate the real rect later
                    // --- FIX: Pass suraNumber here ---
                    ref.read(selectedAyahProvider.notifier).selectByNavigation(suraNumber, ayahNumber);

                    // Close the drawer
                    Navigator.of(context).pop();
                  } else {
                    // Handle case where ayah page is not found (shouldn't happen with complete data)
                    // Optionally show a Snackbar or dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Page data not found for this Ayah')),
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildParaTabView(Map<int, List<int>> paraPageRanges) {
    final selectedPara = ref.watch(selectedNavigationParaProvider);

    if (selectedPara == null) {
      // Show list of all Paras
      return _buildParaList(paraPageRanges);
    } else {
      // Show list of pages for the selected Para
      return _buildParaPageList(selectedPara, paraPageRanges);
    }
  }

  Widget _buildParaList(Map<int, List<int>> paraPageRanges) {
    // Check if data is missing
    if (paraPageRanges.isEmpty) {
      // This state should ideally be caught by the loading checks in _buildSideDrawer
      return const Center(child: Text('Para data not loaded.'));
    }

    return ListView.builder(
      itemCount: 30, // There are 30 Paras
      itemBuilder: (context, index) {
        final paraNumber = index + 1;
        final pageNumbers = paraPageRanges[paraNumber]; // Get the list of pages

        // Display the first page number and the count of pages if available
        final String subtitleText;
        if (pageNumbers != null && pageNumbers.isNotEmpty) {
          subtitleText = 'পৃষ্ঠা ${pageNumbers.first} - ${pageNumbers.last} (${pageNumbers.length} পৃষ্ঠা)';
        } else {
          subtitleText = 'পৃষ্ঠা তথ্য পাওয়া যায়নি';
        }

        return ListTile(
          title: Text('পারা $paraNumber'),
          subtitle: Text(subtitleText),
          onTap: () {
            // Select this para to show its pages
            if (pageNumbers != null && pageNumbers.isNotEmpty) {
              ref.read(selectedNavigationParaProvider.notifier).state = paraNumber;
            } else {
              // Optionally show a message if no page data for this para
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('পৃষ্ঠা তথ্য পাওয়া যায়নি $paraNumber')),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildParaPageList(int paraNumber, Map<int, List<int>> paraPageRanges) {
    // Validate paraNumber and get the page list
    final pageNumbers = paraPageRanges[paraNumber];

    if (pageNumbers == null || pageNumbers.isEmpty) {
      // Should ideally not happen if the Para list was built correctly
      return const Center(child: Text('Page data not found for this Para.'));
    }

    // Get the Para name if you had one (using index is fine for now)
    final paraName = "পারা $paraNumber"; // Placeholder


    return Column(
      children: [
        // Add a "Back" button at the top
        ListTile(
          leading: const Icon(Icons.arrow_back),
          title: Text('$paraName'), // Title can be the Para number
          onTap: () {
            // Go back to the list of all paras
            ref.read(selectedNavigationParaProvider.notifier).state = null;
          },
        ),
        const Divider(height: 1), // Optional divider

        Expanded(
          child: ListView.builder(
            itemCount: pageNumbers.length,
            itemBuilder: (context, index) {
              final pageNumber = pageNumbers[index]; // Get the actual page number

              return ListTile(
                title: Text('পৃষ্ঠা $pageNumber'),
                onTap: () {
                  // Navigate to the selected page number
                  ref.read(navigateToPageCommandProvider.notifier).state = pageNumber;
                  // No ayah highlighting needed here, just page navigation.
                  // Clear any existing ayah highlight if desired when navigating by page
                  ref.read(selectedAyahProvider.notifier).clear();
                  // Close the drawer
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildBookmarkTabView() {
    return DefaultTabController(
      length: 2,
      child: Consumer(
        builder: (_, ref, __) {
          final bookmarksAsync = ref.watch(bookmarkProvider);
          return bookmarksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading bookmarks')),
            data: (bookmarks) {
              final ayahBookmarks = bookmarks
                  .where((b) => b.type == 'ayah')
                  .toList();
              final pageBookmarks = bookmarks
                  .where((b) => b.type == 'page')
                  .toList();

              return Column(
                children: [
                  Container(
                    color: primaryColor.withOpacity(.1),
                    child: const TabBar(
                      labelColor: primaryColor,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(text: 'আয়াত'),
                        Tab(text: 'পৃষ্ঠা'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        ListView.builder(
                          itemCount: ayahBookmarks.length,
                          itemBuilder: (_, i) {
                            final b = ayahBookmarks[i];
                            return ListTile(
                              title: Text(b.identifier),
                              subtitle: Text(
                                'Added: ${b.timestamp.toLocal().toString().split('.').first}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => ref
                                    .read(bookmarkProvider.notifier)
                                    .remove(b.identifier),
                              ),
                            );
                          },
                        ),
                        ListView.builder(
                          itemCount: pageBookmarks.length,
                          itemBuilder: (_, i) {
                            final b = pageBookmarks[i];
                            return ListTile(
                              title: Text('Page ${b.identifier.split('-')[1]}'),
                              subtitle: Text(
                                'Added: ${b.timestamp.toLocal().toString().split('.').first}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => ref
                                    .read(bookmarkProvider.notifier)
                                    .remove(b.identifier),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(currentPageProvider);
    final allBoxesAsync = ref.watch(allBoxesProvider);

    // Listen for navigation commands
    ref.listen<int?>(navigateToPageCommandProvider, (
        prevPageNum,
        newPageNum,
        ) async {
      // Your existing navigation logic here...
      // You'll need the total page count for clamping. Watch it here too.
      final totalPageCountAsync = ref.read(totalPageCountProvider); // Read the provider (no rebuild needed)
      final pageCount = totalPageCountAsync.value ?? 604; // Use loaded value, fallback to a large number if not ready

      if (newPageNum != null) {
        final targetPageIndex = newPageNum - 1; // 0-based index

        if (targetPageIndex >= 0 && targetPageIndex < pageCount) { // Use pageCount from provider
          final currentOrientation = MediaQuery.of(context).orientation;
          final width = MediaQuery.of(context).size.width;

          if (currentOrientation == Orientation.portrait &&
              _portraitCtrl != null) {
            _portraitCtrl!.animateToPage(
              targetPageIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else if (currentOrientation == Orientation.landscape &&
              _landscapeCtrl != null) {
            final itemH = width / _aspect;
            final offset = targetPageIndex * itemH;

            _landscapeCtrl!.animateTo(
              offset,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }

          Future.microtask(() {
            ref.read(navigateToPageCommandProvider.notifier).state = null;
          });
        } else {
          debugPrint(
            'Navigation command received for invalid page number: $newPageNum',
          );
          Future.microtask(() {
            ref.read(navigateToPageCommandProvider.notifier).state = null;
          });
        }
      }
    });

    return allBoxesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold( // Add stacktrace 's' for better debugging
        appBar: _buildAppBar(), // Show app bar even on error
        body: Center(child: Text('Error loading Quran data: ${e.toString()}\n$s')),
      ),
      data: (allBoxes) {
        // Data is loaded, we can now build the main screen
        // Note: We don't strictly *need* allBoxes here, just that the provider has data.
        // We can now watch other data providers like suraMapping, paraMapping etc in _buildSideDrawer.

        // Need total page count here for the ListView/PageView item count
        final totalPageCountAsync = ref.watch(totalPageCountProvider);

        // If total page count is still loading, show a loader within the data state?
        // Or maybe wait for totalPageCountProvider before building the main view?
        // Let's watch totalPageCountProvider directly in the build method.
        return totalPageCountAsync.when(
          loading: () => const Scaffold( // Show loading if page count isn't ready
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, s) => Scaffold( // Handle error if page count fails
            appBar: _buildAppBar(),
            body: Center(child: Text('Error loading page count: ${e.toString()}\n$s')),
          ),
          data: (pageCount) {
            // BOTH allBoxes and totalPageCount are loaded
            return OrientationBuilder(
              builder: (_, ori) {
                // ... rest of your OrientationBuilder logic ...
                final width = MediaQuery.of(context).size.width;
                final itemH = width / _aspect;

                /* create the proper controller if orientation changed */
                if (ori != _lastOri) {
                  // Keep initialPage/initialScrollOffset logic as is using currentPage
                  if (ori == Orientation.portrait) {
                    _portraitCtrl?.dispose();
                    _portraitCtrl = PageController(initialPage: ref.read(currentPageProvider)); // Use ref.read here
                  } else {
                    _landscapeCtrl?.dispose();
                    _landscapeCtrl = ScrollController(
                      initialScrollOffset: ref.read(currentPageProvider) * itemH, // Use ref.read here
                    );
                  }
                  _lastOri = ori;
                }

                Widget viewer;
                if (ori == Orientation.portrait) {
                  viewer = PageView.builder(
                    controller: _portraitCtrl!,
                    reverse: true,
                    itemCount: pageCount, // Use the loaded pageCount
                    onPageChanged: (idx) {
                      ref.read(currentPageProvider.notifier).state = idx;
                      final currentSelectedState = ref.read(selectedAyahProvider);
                      // Clear the selected ayah ONLY if it was selected by audio.
                      if (currentSelectedState?.source == AyahSelectionSource.audio) {
                        ref.read(selectedAyahProvider.notifier).clear();
                      }
                    },
                    itemBuilder: (_, idx) => QuranPage(
                      pageIndex: idx, // Pass 0-based index
                      editionDir: widget.editionDir,
                      imageWidth: widget.imageWidth,
                      imageHeight: widget.imageHeight,
                      imageExt: widget.imageExt,
                    ),
                  );
                } else {
                  /* vertical continuous scroll */
                  viewer = NotificationListener<ScrollUpdateNotification>(
                    onNotification: (n) {
                      final p = (n.metrics.pixels / itemH).round().clamp(
                        0,
                        math.max(0, pageCount - 1), // Use the loaded pageCount
                      );
                      ref.read(currentPageProvider.notifier).state = p.toInt();
                      final currentSelectedState = ref.read(selectedAyahProvider);
                      // Clear the selected ayah ONLY if it was selected by audio.
                      if (currentSelectedState?.source == AyahSelectionSource.audio) {
                        ref.read(selectedAyahProvider.notifier).clear();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _landscapeCtrl!,
                      physics: const BouncingScrollPhysics(),
                      itemCount: pageCount, // Use the loaded pageCount
                      itemBuilder: (_, idx) => SizedBox(
                        height: itemH,
                        width: double.infinity,
                        child: QuranPage(
                          pageIndex: idx, // Pass 0-based index
                          editionDir: widget.editionDir,
                          imageWidth: widget.imageWidth,
                          imageHeight: widget.imageHeight,
                          imageExt: widget.imageExt,
                        ),
                      ),
                    ),
                  );
                }

                return Scaffold(
                  key: _rootKey,
                  drawer: const SideDrawer(), // This will internally watch providers
                  onDrawerChanged: (isOpen) {
                    final drawer = ref.read(drawerOpenProvider.notifier);
                    isOpen ? drawer.open() : drawer.close();
                  },
                  appBar: _buildAppBar(),
                  bottomNavigationBar: BottomBar(
                    drawerOpen: ref.watch(drawerOpenProvider),
                    rootKey: _rootKey,
                  ),
                  body: Stack(
                    children: [
                      viewer,
                      Consumer(
                        builder: (context, ref, _) {
                          final audio = ref.watch(quranAudioProvider);
                          if (audio == null) {
                            return const SizedBox.shrink();
                          }
                          return Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: AudioControllerBar(
                              color: Theme.of(context).primaryColor,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
