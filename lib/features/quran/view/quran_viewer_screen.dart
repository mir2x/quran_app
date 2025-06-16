import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/quran/view/widgets/audio_control_bar.dart';
import 'package:quran_app/features/quran/view/widgets/bottom_bar.dart';
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
      ref.read(editionDirProvider.notifier).set(widget.editionDir);
    });
    _pageCountF = _detectPageCount();
  }

  Future<int> _detectPageCount() async =>
      (await widget.editionDir
              .list()
              .where((f) => f.path.endsWith('.${widget.imageExt}'))
              .toList())
          .length;

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

  Widget _buildSideDrawer() {
    return Align(
      alignment: Alignment.topLeft,
      child: Builder(
        builder: (context) {
          final media = MediaQuery.of(context);
          final double topInset = kToolbarHeight + media.padding.top;
          final double bottomInset = bottomBarHeight + media.padding.bottom;

          // Watch the mappings and ayah counts
          final suraMapping = ref.watch(suraPageMappingProvider);
          final paraMapping = ref.watch(paraPageMappingProvider);
          final ayahMapping = ref.watch(ayahPageMappingProvider);
          final ayahCounts = ref.watch(ayahCountsProvider);
          final suraNames = ref.watch(suraNamesProvider); // Get sura names

          // Check if main data (allBoxesProvider) is still loading or has error
          final allBoxesAsync = ref.watch(allBoxesProvider);
          final bool isLoading = allBoxesAsync.isLoading;
          final bool hasError = allBoxesAsync.hasError;


          // Determine content based on loading/error state
          Widget suraParaContent;
          if (isLoading) {
            suraParaContent = const Center(child: CircularProgressIndicator());
          } else if (hasError) {
            suraParaContent = Center(child: Text('Error loading data: ${allBoxesAsync.error}'));
          } else if (suraMapping.isEmpty || paraMapping.isEmpty || ayahMapping.isEmpty) {
            // This state might be hit briefly even after data is loaded if mappings are being built.
            // Could indicate an issue if it persists.
            suraParaContent = const Center(child: Text('Processing data...'));
          }
          else {
            // Data is ready, build the tab views
            suraParaContent = TabBarView(
              children: [
                // Pass necessary data to the updated Surah tab view
                _buildSurahAyahTabView(suraMapping, ayahCounts, suraNames, ayahMapping),
                _buildParaListTabView(paraMapping),
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
                        child: suraParaContent,
                      ),
                      // ... Your TabBar remains the same ...
                      Container(
                        color: const Color(0xFFB2FF59), // Light green
                        child: TabBar(
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.black87,
                          indicator: BoxDecoration(
                            color: const Color(0xFF1B5E20), // Full dark green for active tab
                            borderRadius: BorderRadius.zero,
                          ),
                          indicatorSize: TabBarIndicatorSize.tab, // Fills the whole tab
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
            ),
          );
        },
      ),
    );
  }

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


  // Helper method to build the list of all Surahs
  Widget _buildSurahList(Map<int, int> suraMapping, List<int> ayahCounts, List<String> suraNames) {
    // Check if data is missing (shouldn't happen if we only reach here when data is loaded)
    if (suraNames.length < 114 || ayahCounts.length < 114 || suraMapping.isEmpty) {
      return const Center(child: Text('Data incomplete.'));
    }

    return ListView.builder(
      itemCount: 114,
      itemBuilder: (context, index) {
        final suraNumber = index + 1;
        final startPage = suraMapping[suraNumber]; // Use the mapping
        final totalAyahs = ayahCounts[index]; // Ayah counts list is 0-indexed
        final surahName = suraNames[index]; // Sura names list is 0-indexed

        return ListTile(
          title: Text('$suraNumber. $surahName'),
          subtitle: Text('আয়াত: $totalAyahs, পৃষ্ঠা: ${startPage ?? 'N/A'}'), // Show ayah count and start page
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
    final surahName = suraNames[suraNumber - 1]; // Sura names list is 0-indexed


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
                    ref.read(selectedAyahProvider.notifier).selectFromAudio(ayahNumber); // Use selectFromAudio or add a new method like selectForNavigation

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

  Widget _buildParaListTabView(Map<int, int> paraMapping) {
    return ListView.builder(
      itemCount: 30,
      itemBuilder: (context, index) {
        final paraNumber = index + 1;
        final startPage = paraMapping[paraNumber];
        final paraName = "পারা $paraNumber";
        return ListTile(
          title: Text('$paraName'),
          trailing: Text('পৃষ্ঠা $startPage'), // Show the page number
          onTap: () {
            if (startPage != null) {
              ref.read(navigateToPageCommandProvider.notifier).state = startPage;
              Navigator.of(context).pop();
            }
          },
        );
      },
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
    final suraMapping = ref.watch(suraPageMappingProvider);
    final paraMapping = ref.watch(paraPageMappingProvider);
    final currentPage = ref.watch(currentPageProvider);
    ref.listen<int?>(navigateToPageCommandProvider, (
      prevPageNum,
      newPageNum,
    ) async {
      if (newPageNum != null) {
        final targetPageIndex = newPageNum - 1;

        final pageCount = await _pageCountF;

        if (targetPageIndex >= 0 && targetPageIndex < pageCount) {
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

    return FutureBuilder<int>(
      future: _pageCountF,
      builder: (_, s) {
        if (!s.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final pageCount = s.data!;
        return OrientationBuilder(
          builder: (_, ori) {
            final width = MediaQuery.of(context).size.width;
            final itemH = width / _aspect;

            /* create the proper controller if orientation changed */
            if (ori != _lastOri) {
              if (ori == Orientation.portrait) {
                _portraitCtrl?.dispose();
                _portraitCtrl = PageController(initialPage: currentPage);
              } else {
                _landscapeCtrl?.dispose();
                _landscapeCtrl = ScrollController(
                  initialScrollOffset: currentPage * itemH,
                );
              }
              _lastOri = ori;
            }

            Widget viewer;
            if (ori == Orientation.portrait) {
              viewer = PageView.builder(
                controller: _portraitCtrl!,
                reverse: true,
                itemCount: pageCount,
                onPageChanged: (idx) {
                  ref.read(currentPageProvider.notifier).state = idx;
                  if (ref.watch(quranAudioProvider) == null) {
                    ref.read(selectedAyahProvider.notifier).clear();
                  }
                },
                itemBuilder: (_, idx) => QuranPage(
                  pageIndex: idx,
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
                    math.max(0, pageCount - 1),
                  );
                  ref.read(currentPageProvider.notifier).state = p.toInt();
                  if (ref.watch(quranAudioProvider) == null) {
                    ref.read(selectedAyahProvider.notifier).clear();
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _landscapeCtrl!,
                  physics: const BouncingScrollPhysics(),
                  itemCount: pageCount,
                  itemBuilder: (_, idx) => SizedBox(
                    height: itemH,
                    width: double.infinity,
                    child: QuranPage(
                      pageIndex: idx,
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
              drawer: _buildSideDrawer(),
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
  }
}
