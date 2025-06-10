import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/utils/bengali_utils.dart';
import '../../../../core/utils/no_scrollbar_behaviour.dart';
import '../../data/data_sources/quran_data.dart';
import '../../domain/entities/ayah_audio_range.dart';
import '../../domain/entities/ayah_region.dart';

import '../providers/bookmark/bookmark.dart';
import '../providers/bookmark/bookmark_provider.dart';
import '../providers/quran_provider.dart';

class QuranScreen extends ConsumerStatefulWidget {
  final String assetPath;
  final int imageWidth;
  final int imageHeight;
  final List<String> imageFiles;
  const QuranScreen({super.key, required this.assetPath, required this.imageWidth, required this.imageHeight, required this.imageFiles});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  late final StreamSubscription<PlayerState> _playerSub;
  final GlobalKey _menuKey = GlobalKey();
  final AudioPlayer _player = AudioPlayer();

  final PageController _pageController = PageController(initialPage: 0);
  final ScrollController _landscapePageController = ScrollController();
  final ScrollController _ayahScrollController = ScrollController();

  static const double bottomBarHeight = 56.0;
  static const double _menuVerticalOffset = 20.0;

  List<AyahRegion> regions = [];
  Map<int, List<AyahRegion>> pageRegions = {};
  List<AyahAudioRange> ayahTimings = [];

  late Stream<Duration> _positionStream;
  StreamSubscription<Duration>? _positionSubscription;

  late String _imageBaseDir;
  late String _jsonBaseDir;

  @override
  void initState() {
    super.initState();
    _prepareLocalDirs();
    _landscapePageController.addListener(_handleLandscapeScroll);

    final quranNotifier = ref.read(quranProvider.notifier);
    final currentReciter = ref.read(quranProvider).selectedReciter;

    _changeReciter(currentReciter);
    _loadAudioForReciter(currentReciter);

    _pageController.addListener(() {
      final newPage = (_pageController.page ?? 0).round() + 1;
      if (newPage != ref.read(quranProvider).currentPage) {
        quranNotifier.setCurrentPage(newPage);
        quranNotifier.hideAyahMenu();
      }
    });

    _positionStream = _player.positionStream;
    _positionSubscription = _positionStream.listen((pos) {
      for (int i = 0; i < ayahTimings.length; i++) {
        final timing = ayahTimings[i];
        if (pos >= timing.start && pos < timing.end) {
          if (ref.read(quranProvider).highlightedAyah != timing.key) {
            quranNotifier.setHighlightedAyah(timing.key);
            quranNotifier.setCurrentAyahIdx(i);
          }
          break;
        }
      }
    });

    _playerSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        quranNotifier.setPlaying(false);
      }
    });
  }


  Future<void> _prepareLocalDirs() async {
    final notifier = ref.read(quranProvider.notifier);
    final docs = await getApplicationDocumentsDirectory();
    _imageBaseDir = '${docs.path}/downloads/image/${widget.assetPath}';
    _jsonBaseDir  = '${docs.path}/downloads/image_json/${widget.assetPath}';

    for (var i = 1; i <= widget.imageFiles.length; i++) {
      final path = '$_imageBaseDir/page-${i.toString().padLeft(3, '0')}.jpg';
      precacheImage(FileImage(File(path)), context);
    }

    notifier.setLocalDirsReady();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _positionSubscription?.cancel();
    _player.dispose();
    _playerSub.cancel();
    _ayahScrollController.dispose();
    _menuKey.currentState?.dispose();
    _landscapePageController.removeListener(_handleLandscapeScroll);
    super.dispose();
  }

  void _handleLandscapeScroll() {
    final newPage =
        (_landscapePageController.offset / ref.read(quranProvider).landscapeItemExtent).floor() + 1;
    if (newPage != ref.read(quranProvider).currentPage) {
      ref.read(quranProvider.notifier).setCurrentPage(newPage);
      ref.read(quranProvider.notifier).hideAyahMenu();
    }
  }

// ───────────────────────── ayah menu helpers ─────────────────────────

  void _playSelectedAyah() {
    if (ref.read(quranProvider).highlightedAyah == null) return;

    final index = ayahTimings.indexWhere(
            (timing) => timing.key == ref.read(quranProvider).highlightedAyah);
    if (index != -1) {
      _playAyahs(index, index);
    }
  }

  void _addNoteToAyah() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: const TextField(
          decoration: InputDecoration(hintText: 'Enter your note...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note saved')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _shareAyah() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing ayah...')),
    );
  }

  void _copyAyahText() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ayah text copied')),
    );
  }

// ───────────────────────── bookmarks ─────────────────────────

  int _getCurrentPageNumber() {
    final orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.portrait) {
      return (_pageController.page?.round() ?? 0) + 1;
    } else {
      return (_landscapePageController.position.pixels / ref.read(quranProvider).landscapeItemExtent)
          .floor() +
          1;
    }
  }

  void _navigateToBookmark(Bookmark bookmark) async {
    final notifier = ref.read(quranProvider.notifier);

    if (bookmark.type == 'ayah') {
      final pageNum = ayahToPage[bookmark.identifier];
      if (pageNum != null) {
        await _navigateToPage(pageNum);
        if (!mounted) return;

        notifier.setAyahBookmark(
          ayahKey: bookmark.identifier,
          showBars: false,
          isDrawerOpen: false,
        );

        await loadRegionsForPage(pageNum);
      }
    } else {
      final pageNum = int.parse(bookmark.identifier);
      await _navigateToPage(pageNum);

      notifier.setPageBookmark(
        showBars: false,
        isDrawerOpen: false,
      );
    }
  }

// ───────────────────────── audio helpers ─────────────────────────

  Future<void> _changeReciter(String reciter) async {
    final audioPath = reciterAudioAssets[reciter];
    if (audioPath != null) {
      await _player.setAsset(audioPath);
      ref.read(quranProvider.notifier).changeReciter(reciter);
      ayahTimings.clear();
      await _loadAudioForReciter(reciter);
    } else {
      return;
    }
  }

  Future<void> _loadAudioForReciter(String reciter) async {
    final jsonPath = reciterAudioJsons[reciter];
    if (jsonPath == null) {
      return;
    }
    ayahTimings = await AyahAudioRange.loadFromAsset(jsonPath);
  }

  void _playAyahs(int fromAyah, int toAyah) async {
    final notifier = ref.read(quranProvider.notifier);
    if (ayahTimings.isEmpty) {
      return;
    }
    _positionSubscription?.cancel();

    final start = ayahTimings[fromAyah].start;
    final end = ayahTimings[toAyah].end;
    notifier
      ..setCurrentEndPosition(end)
      ..setCurrentAyahIdx(fromAyah)
      ..showAudioController(true)
      ..setPlaying(true);

    _player.seek(start);

    _positionSubscription = _positionStream.listen((pos) {
      if (pos >= end) {
        _player.pause();
        _player.seek(end);
        notifier.setPlaying(false);
        return;
      }
      for (int i = 0; i < ayahTimings.length; i++) {
        final timing = ayahTimings[i];
        if (pos >= timing.start && pos < timing.end) {
          if (ref.read(quranProvider).highlightedAyah != timing.key) {
            notifier.setHighlightedAyah(timing.key);
            notifier.setCurrentAyahIdx(i);
          }
          break;
        }
      }
    });
    try {
      await _player.seek(start);
      _player.play();
      notifier.setPlaying(true);
      notifier.showAudioController(true);
      notifier.setCurrentAyahIdx(fromAyah);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _togglePlayPause() async {
    final notifier = ref.read(quranProvider.notifier);
    final isPlaying = ref.read(quranProvider).isPlaying;
    if (_player.playerState.processingState == ProcessingState.idle) {
      return;
    }
    if (!isPlaying) {
      await _player.play();
      notifier.setPlaying(true);
    } else {
      await _player.pause();
      notifier.setPlaying(false);
    }
  }

  void _stopPlayback() {
    _player.stop();
    final notifier = ref.read(quranProvider.notifier);
    notifier.setPlaying(false);
    notifier.showAudioController(false);
  }

  void _playPrev() {
    final currentAyahIdx = ref.read(quranProvider).currentAyahIdx;
    if (currentAyahIdx <= 0) {
      return;
    }
    _playAyahs(currentAyahIdx - 1, currentAyahIdx - 1);
  }

  void _playNext() {
    final currentAyahIdx = ref.read(quranProvider).currentAyahIdx;
    if (currentAyahIdx >= ayahTimings.length - 1) {
      return;
    }
    _playAyahs(currentAyahIdx + 1, currentAyahIdx + 1);
  }

  Future<void> _toggleOrientation() async {
    final notifier = ref.read(quranProvider.notifier);
    final currentOrientation = MediaQuery.of(context).orientation;
    notifier.hideAyahMenu();
    if (currentOrientation == Orientation.portrait) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      notifier.setShowBars(false);
      notifier.needScrollAdjustment();
    } else {
      final currentPage = ref.read(quranProvider).currentPage;
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(currentPage - 1);
        }
      });
      notifier.setShowBars(true);
    }
  }

  Future<void> loadRegionsForPage(int pageNumber) async {
    if (pageRegions.containsKey(pageNumber)) return;
    try {
      final jsonPath =
          '$_jsonBaseDir/page-${pageNumber.toString().padLeft(3, '0')}.json';

      final jsonStr = await File(jsonPath).readAsString();
      final parsed  = await parseGroupedRegions(jsonStr);
      setState(() {
        pageRegions[pageNumber] = parsed;
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _navigateToPage(int pageNum) async {
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;
    final screenWidth = MediaQuery.of(context).size.width;

    await loadRegionsForPage(pageNum);

    if (isPortrait) {
      await _pageController.animateToPage(
        pageNum - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final landscapeItemExtent =
          widget.imageHeight * (screenWidth / widget.imageWidth);
      final position = (pageNum - 1) * landscapeItemExtent;
      await _landscapePageController.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quranState = ref.watch(quranProvider);
    final notifier = ref.read(quranProvider.notifier);

    final ThemeData theme = Theme.of(context);
    final Color primaryColor = theme.primaryColor;

    if (!quranState.localDirsReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final orientation = MediaQuery.of(context).orientation;
        if (orientation == Orientation.landscape) {
          await _toggleOrientation();
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: quranState.showBars
            ? AppBar(
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: notifier.toggleDrawer,
          ),
          title: const Text(
            'কুরআন মজীদ',
            style: TextStyle(
                fontFamily: 'SolaimanLipi',
                fontSize: 22,
                color: Colors.white),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              tooltip: 'Search',
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.nightlight_outlined,
                  color: Colors.white),
              tooltip: 'Settings',
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.g_translate, color: Colors.white),
              tooltip: 'Text Settings',
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //       builder: (context) => const SurahPage()),
                // );
              },
            ),
          ],
          elevation: 4.0,
        )
            : null,
        bottomNavigationBar: quranState.showBars
            ? BottomAppBar(
          color: primaryColor,
          height: bottomBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          elevation: 4.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                tooltip: 'Audio Settings',
                onPressed: () => _showAudioSettings(context),
              ),
              SizedBox(
                width: 150,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: quranState.selectedReciter,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Colors.white),
                    iconSize: 24,
                    // Explicit icon size
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16),
                    dropdownColor: Theme.of(context).primaryColor,
                    onChanged: (String? newValue) {
                      if (newValue != null) _changeReciter(newValue);
                    },
                    selectedItemBuilder: (BuildContext context) {
                      return reciters.map<Widget>((String value) {
                        return SizedBox(
                          width: 126, // 150 - 24 (icon width)
                          height: 48,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: 'SolaimanLipi',
                                  fontSize: 16),
                            ),
                          ),
                        );
                      }).toList();
                    },
                    items: reciters
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Container(
                          height: 48,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'SolaimanLipi', fontSize: 16),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.touch_app_outlined,
                      color: quranState.touchModeEnabled
                          ? Colors.orangeAccent
                          : Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Touch Mode',
                    onPressed: () {
                      notifier.toggleTouchMode();
                      if (!quranState.touchModeEnabled) {
                        notifier.setHighlightedAyah(null);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.screen_rotation_outlined,
                        color: Colors.white, size: 22),
                    tooltip: 'Rotate Screen',
                    onPressed: _toggleOrientation,
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () async {
                      final currentPage = _getCurrentPageNumber();
                      final bookmark = Bookmark(
                        type: 'page',
                        identifier: currentPage.toString(),
                      );
                      ref.read(bookmarkProvider.notifier).add(bookmark);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'পৃষ্ঠা $currentPage বুকমার্ক করা হয়েছে')),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      quranState.isDrawerOpen
                          ? Icons.arrow_downward_outlined
                          : Icons.arrow_upward_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Toggle Drawer',
                    onPressed: () {
                      notifier.toggleDrawer();
                    },
                  ),
                ],
              )
            ],
          ),
        )
            : null,
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (quranState.showAyahMenu) {
                    notifier.hideAyahMenu();
                  }
                  if (quranState.isDrawerOpen) {
                    notifier.closeDrawer();
                  }
                },
                onDoubleTap: () {
                  setState(() {
                    if (quranState.isDrawerOpen) {
                      notifier.closeDrawer();
                    }
                    notifier.toggleBars();
                  });
                },
                child: OrientationBuilder(
                  builder: (context, orientation) {
                    final isPortrait = orientation == Orientation.portrait;

                    if (!isPortrait) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final newExtent = widget.imageHeight * (screenWidth / widget.imageWidth);

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        // avoid useless rebuilds
                        if (ref.read(quranProvider).landscapeItemExtent != newExtent) {
                          ref.read(quranProvider.notifier).setLandscapeItemExtent(newExtent);
                        }
                      });
                      if (quranState.needsScrollAdjustment) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final position = (quranState.currentPage - 1) * quranState.landscapeItemExtent;
                          if (_landscapePageController.hasClients) {
                            _landscapePageController.jumpTo(position);
                          }
                          notifier.doneScrollAdjustment();
                        });
                      }
                    }

                    final pageView = PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        notifier.setCurrentPage(index + 1);
                      },
                      reverse: isPortrait,
                      scrollDirection:
                      isPortrait ? Axis.horizontal : Axis.vertical,
                      itemCount: 11,
                      physics: const PageScrollPhysics(),
                      pageSnapping: true,
                      itemBuilder: (context, index) {
                        final pageNumber = index + 1;
                        final imagePath = '$_imageBaseDir/page-${pageNumber.toString().padLeft(3, '0')}.jpg';

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          loadRegionsForPage(pageNumber);
                        });

                        final regions = pageRegions[pageNumber] ?? [];

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            if (isPortrait) {
                              final scaleX =
                                  constraints.maxWidth / widget.imageWidth;
                              final scaleY =
                                  constraints.maxHeight / widget.imageHeight;

                              return Stack(
                                children: [
                                  Image.file(
                                    File(imagePath),
                                    fit: BoxFit.fill,
                                    width: constraints.maxWidth,
                                    height: constraints.maxHeight,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: Center(
                                            child: Text(
                                                'Error loading page $pageNumber')),
                                      );
                                    },
                                  ),
                                  ...regions.expand((ayah) {
                                    final isHighlighted =
                                        quranState.highlightedAyah == ayah.key;
                                    return ayah.boxes.map((box) {
                                      return Positioned(
                                        left: box.x * scaleX,
                                        top: box.y * scaleY,
                                        width: box.width * scaleX,
                                        height: box.height * scaleY,
                                        child: GestureDetector(
                                          onTap: () {
                                            if (!quranState.touchModeEnabled) return;

                                            final currentRegions = pageRegions[quranState.currentPage];
                                            if (currentRegions == null) return;

                                            final ayahRegion = currentRegions.firstWhere(
                                                  (r) => r.key == ayah.key,
                                              orElse: () => AyahRegion(sura: '', ayah: '', boxes: []),
                                            );
                                            if (ayahRegion.boxes.isEmpty) return;

                                            Offset? pos;
                                            if (quranState.highlightedAyah != ayah.key) {
                                              final box = ayahRegion.boxes.first;
                                              final dx  = box.x * scaleX;
                                              final dy  = box.y * scaleY;

                                              final rb  = context.findRenderObject() as RenderBox;
                                              final global = rb.localToGlobal(Offset(dx, dy));
                                              final local  = rb.globalToLocal(global);

                                              const menuHeight = 52.0;
                                              pos = Offset(
                                                local.dx,
                                                (local.dy - menuHeight - _menuVerticalOffset).clamp(0, double.infinity),
                                              );
                                            }

                                            notifier.toggleAyahHighlight(ayah.key, menuPos: pos);
                                          },


                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: isHighlighted
                                                    ? Colors.orange
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                              color: isHighlighted
                                                  ? Colors.orange.withAlpha(
                                                  (0.3 * 255).toInt())
                                                  : Colors.transparent,
                                            ),
                                          ),
                                        ),
                                      );
                                    });
                                  }),
                                  _buildAyahMenu(),
                                ],
                              );
                            } else {
                              final screenWidth =
                                  MediaQuery.of(context).size.width;
                              final landscapeItemExtent = widget.imageHeight *
                                  (screenWidth / widget.imageWidth);

                              return ListView.builder(
                                controller: _landscapePageController,
                                itemCount: 11,
                                itemExtent: landscapeItemExtent,
                                itemBuilder: (context, index) {
                                  final pageNumber = index + 1;
                                  final imagePath = '$_imageBaseDir/page-${pageNumber.toString().padLeft(3, '0')}.jpg';
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    loadRegionsForPage(pageNumber);
                                  });

                                  final regions = pageRegions[pageNumber] ?? [];

                                  return LayoutBuilder(
                                    builder: (context, constraints) {
                                      final scale =
                                          constraints.maxWidth / widget.imageWidth;
                                      final scaledHeight =
                                          widget.imageHeight * scale;

                                      return SizedBox(
                                        width: constraints.maxWidth,
                                        height: scaledHeight,
                                        child: Stack(
                                          children: [
                                            Image.file(
                                              File(imagePath),
                                              width: constraints.maxWidth,
                                              height: scaledHeight,
                                              fit: BoxFit.fitWidth,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: Center(
                                                    child: Text(
                                                        'Error loading page $pageNumber'),
                                                  ),
                                                );
                                              },
                                            ),
                                            ...regions.expand((ayah) {
                                              final isHighlighted =
                                                  quranState.highlightedAyah ==
                                                      ayah.key;
                                              return ayah.boxes.map(
                                                    (box) => Positioned(
                                                  left: box.x * scale,
                                                  top: box.y * scale,
                                                  width: box.width * scale,
                                                  height: box.height * scale,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      if (quranState
                                                          .touchModeEnabled) {
                                                        final currentRegions =
                                                        pageRegions[quranState
                                                            .currentPage];
                                                        if (currentRegions ==
                                                            null) {
                                                          return;
                                                        }

                                                        final ayahRegion =
                                                        currentRegions
                                                            .firstWhere(
                                                              (r) =>
                                                          r.key == ayah.key,
                                                          orElse: () =>
                                                              AyahRegion(
                                                                  sura: '',
                                                                  ayah: '',
                                                                  boxes: []),
                                                        );

                                                        if (ayahRegion.boxes
                                                            .isEmpty) {
                                                          return;
                                                        }

                                                        final firstBox =
                                                            ayahRegion
                                                                .boxes.first;
                                                        final isSameAyah =
                                                            quranState
                                                                .highlightedAyah ==
                                                                ayah.key;

                                                        notifier
                                                            .setHighlightedAyah(
                                                            isSameAyah
                                                                ? null
                                                                : ayah.key);
                                                        notifier
                                                            .setShowAyahMenu(
                                                            !isSameAyah);

                                                        if (!isSameAyah) {
                                                          // Calculate menu position
                                                          final firstBoxRect =
                                                          Rect.fromLTRB(
                                                            firstBox.x * scale,
                                                            firstBox.y * scale,
                                                            (firstBox.x +
                                                                firstBox
                                                                    .width) *
                                                                scale,
                                                            (firstBox.y +
                                                                firstBox
                                                                    .height) *
                                                                scale,
                                                          );

                                                          final RenderBox
                                                          renderBox =
                                                          context.findRenderObject()
                                                          as RenderBox;
                                                          final globalPosition =
                                                          renderBox.localToGlobal(
                                                              firstBoxRect
                                                                  .topLeft);

                                                          final parentRenderBox =
                                                          context.findAncestorRenderObjectOfType<
                                                              RenderBox>()!;
                                                          final localPosition =
                                                          parentRenderBox
                                                              .globalToLocal(
                                                              globalPosition);

                                                          final menuHeight =
                                                          52.0;
                                                          final adjustedY = (localPosition
                                                              .dy -
                                                              menuHeight -
                                                              _menuVerticalOffset)
                                                              .clamp(
                                                              0,
                                                              double
                                                                  .infinity);

                                                          notifier.setMenuPosition(
                                                              Offset(
                                                                  localPosition
                                                                      .dx,
                                                                  adjustedY
                                                                      .toDouble()));
                                                        } else {
                                                          notifier
                                                              .setMenuPosition(
                                                              null);
                                                        }
                                                      }
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color: isHighlighted
                                                              ? Colors.orange
                                                              : Colors
                                                              .transparent,
                                                          width: 2,
                                                        ),
                                                        color: isHighlighted
                                                            ? Colors.orange
                                                            .withAlpha(
                                                            (0.3 * 255)
                                                                .toInt())
                                                            : Colors
                                                            .transparent,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                            _buildAyahMenu(),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            }
                          },
                        );
                      },
                    );

                    return pageView;
                  },
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: 0.0,
              bottom: 0.0,
              left: quranState.isDrawerOpen ? 0 : -250,
              width: 250,
              child: Material(
                elevation: 0.0,
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      Container(
                        color: primaryColor,
                        child: TabBar(
                          labelColor: Colors.white,
                          unselectedLabelColor:
                          Colors.white.withAlpha((0.7 * 255).toInt()),
                          indicatorColor: Colors.white,
                          indicatorWeight: 3.0,
                          labelStyle: const TextStyle(
                              fontFamily: 'SolaimanLipi',
                              fontSize: 15,
                              fontWeight: FontWeight.w500),
                          tabs: const [
                            Tab(text: 'সূরা'),
                            Tab(text: 'পারা'),
                            Tab(text: 'বুকমার্ক'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildSurahTabView(),
                            _buildParaTabView(),
                            _buildBookmarkTabView(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 250),
                offset: quranState.showAudioController
                    ? Offset.zero
                    : const Offset(0, 1),
                child: _buildAudioControllerBar(primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahTabView() {
    final quranState = ref.watch(quranProvider);
    final notifier = ref.read(quranProvider.notifier);
    final Color selectedTileColor =
    Theme.of(context).primaryColor.withAlpha((0.8 * 255).toInt());

    return Row(
      children: [
        Expanded(
          child: ScrollConfiguration(
            behavior: NoScrollbarBehavior(),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: surahNames.length,
              itemBuilder: (context, index) {
                bool isSelected = quranState.selectedSurahIndex == index;
                return ListTile(
                  title: Text(surahNames[index],
                      style:
                      TextStyle(fontFamily: 'SolaimanLipi', fontSize: 18)),
                  selected: isSelected,
                  selectedTileColor: selectedTileColor,
                  selectedColor: Colors.white,
                  dense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
                  onTap: () {
                    notifier.selectSurah(index);
                    _ayahScrollController.jumpTo(0);
                  },
                );
              },
            ),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
        // Ayah list
        Expanded(
          child: ScrollConfiguration(
            behavior: NoScrollbarBehavior(),
            child: ListView.builder(
              controller: _ayahScrollController,
              padding: EdgeInsets.zero,
              itemCount: quranState.selectedSurahIndex != null
                  ? ayahCounts[quranState.selectedSurahIndex!]
                  : 50,
              itemBuilder: (context, index) {
                bool isSelected = quranState.selectedAyahIndex == index;
                return ListTile(
                  title: Text(
                    toBanglaNumber(index + 1),
                    style: TextStyle(fontFamily: 'SolaimanLipi'),
                  ),
                  selected: isSelected,
                  selectedTileColor: selectedTileColor,
                  selectedColor: Colors.white,
                  dense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                  onTap: () async {
                    if (quranState.selectedSurahIndex == null) return;

                    final surahNumber = quranState.selectedSurahIndex! + 1;
                    final ayahNumber = index + 1;

                    final key =
                        '${surahNumber.toString().padLeft(3, '0')}:${ayahNumber.toString().padLeft(3, '0')}';
                    notifier.selectAyah(index, key);
                    notifier.closeDrawer();
                    notifier.setShowBars(false);

                    final orientation = MediaQuery.of(context).orientation;
                    final pageNum = ayahToPage[key];
                    final screenWidth = MediaQuery.of(context).size.width;
                    if (pageNum != null) {
                      await loadRegionsForPage(pageNum);
                      if (orientation == Orientation.landscape) {
                        final ayahRegions = pageRegions[pageNum]
                            ?.where((region) => region.key == key)
                            .toList();

                        if (ayahRegions != null && ayahRegions.isNotEmpty) {
                          final firstBox = ayahRegions.first.boxes.first;
                          final boxY = firstBox.y;
                          final landscapeItemExtent =
                              widget.imageHeight * (screenWidth / widget.imageWidth);
                          final scaledY =
                              (boxY / widget.imageHeight) * landscapeItemExtent;
                          final targetPosition =
                              (pageNum - 1) * landscapeItemExtent + scaledY;

                          _landscapePageController.jumpTo(targetPosition);
                        } else {
                          _navigateToPage(pageNum); // Fallback to page top
                        }
                      } else {
                        _navigateToPage(pageNum); // Portrait mode
                      }
                    }
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParaTabView() {
    final quranState = ref.watch(quranProvider);
    final notifier = ref.read(quranProvider.notifier);
    final Color selectedTileColor =
    Theme.of(context).primaryColor.withAlpha((0.8 * 255).toInt());

    return Row(
      children: [
        // Para names column
        Expanded(
          child: ScrollConfiguration(
            behavior: NoScrollbarBehavior(),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: paraNames.length,
              itemBuilder: (context, index) {
                bool isSelected = quranState.selectedParaIndex == index;
                return ListTile(
                  title: Text(paraNames[index]),
                  selected: isSelected,
                  selectedTileColor: selectedTileColor,
                  selectedColor: Colors.white,
                  dense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
                  onTap: () {
                    notifier.selectPara(index);
                  },
                );
              },
            ),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
        // Para page numbers column
        Expanded(
          child: ScrollConfiguration(
            behavior: NoScrollbarBehavior(),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: paraPageNumbers.length,
              itemBuilder: (context, index) {
                return ListTile(
                    title: Text('${paraPageNumbers[index]}'),
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 0));
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookmarkTabView() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color:
            Theme.of(context).primaryColor.withAlpha((0.1 * 255).toInt()),
            child: TabBar(
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 2.0,
              tabs: const [
                Tab(text: 'আয়াত'),
                Tab(text: 'পৃষ্ঠা'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAyahBookmarksList(),
                _buildPageBookmarksList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyahBookmarksList() {
    final bookmarksAsync = ref.watch(bookmarkProvider);

    return bookmarksAsync.when(
      loading: () => _emptyState('লোড হচ্ছে...'),
      error: (e, _) => _emptyState('ত্রুটি: $e'),
      data: (list) {
        final ayahBookmarks = list.where((b) => b.type == 'ayah').toList();
        if (ayahBookmarks.isEmpty) return _emptyState('কোন আয়াত বুকমার্ক নেই');
        return ListView.builder(
          itemCount: ayahBookmarks.length,
          itemBuilder: (_, i) {
            final bm = ayahBookmarks[i];
            return ListTile(
              leading: const Icon(Icons.text_snippet),
              title: Text('আয়াত ${bm.identifier}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () =>
                    ref.read(bookmarkProvider.notifier).remove(bm.identifier),
              ),
              onTap: () => _navigateToBookmark(bm),
            );
          },
        );
      },
    );
  }

  Widget _buildPageBookmarksList() {
    final bookmarksAsync = ref.watch(bookmarkProvider);

    return bookmarksAsync.when(
      loading: () => _emptyState('লোড হচ্ছে...'),
      error: (e, _) => _emptyState('ত্রুটি: $e'),
      data: (list) {
        final pageBookmarks = list.where((b) => b.type == 'page').toList();
        if (pageBookmarks.isEmpty) {
          return _emptyState('কোন পৃষ্ঠা বুকমার্ক নেই');
        }
        return ListView.builder(
          itemCount: pageBookmarks.length,
          itemBuilder: (_, i) {
            final bm = pageBookmarks[i];
            return ListTile(
              leading: const Icon(Icons.book),
              title: Text('পৃষ্ঠা ${bm.identifier}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () =>
                    ref.read(bookmarkProvider.notifier).remove(bm.identifier),
              ),
              onTap: () => _navigateToBookmark(bm),
            );
          },
        );
      },
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bookmark_border, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioControllerBar(Color color) {
    final quranState = ref.watch(quranProvider);

    if (!quranState.showAudioController) return const SizedBox.shrink();

    final surah = quranState.selectedSurahIndex != null
        ? surahNames[quranState.selectedSurahIndex!]
        : '';
    final ayah = quranState.currentAyahIdx + 1;

    return Material(
      elevation: 6,
      color: color,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Text('$surah : $ayah',
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                  tooltip: 'Previous Ayah',
                  onPressed: _playPrev,
                ),
                IconButton(
                  icon: Icon(
                      quranState.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white),
                  tooltip: quranState.isPlaying ? 'Pause' : 'Play',
                  onPressed: _togglePlayPause,
                ),
                IconButton(
                  icon: const Icon(Icons.stop, color: Colors.white),
                  tooltip: 'Stop',
                  onPressed: _stopPlayback,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                  tooltip: 'Next Ayah',
                  onPressed: _playNext,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAyahMenu() {
    final quranState = ref.watch(quranProvider);
    final notifier = ref.read(quranProvider.notifier);

    if (!quranState.showAyahMenu || quranState.menuPosition == null) {
      return const SizedBox();
    }

    return Positioned(
      left: 0,
      right: 0,
      top: quranState.menuPosition!.dy,
      child: Center(
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Builder(
            builder: (context) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.2 * 255).toInt()),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuIcon(Icons.bookmark, 'Bookmark Ayah', () {
                      if (quranState.highlightedAyah != null) {
                        final bookmark = Bookmark(
                          type: 'ayah',
                          identifier: quranState.highlightedAyah!,
                        );
                        ref.read(bookmarkProvider.notifier).add(bookmark);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('আয়াত বুকমার্ক করা হয়েছে')),
                        );
                      }
                      notifier.setShowAyahMenu(false);
                    }),
                    _buildMenuIcon(Icons.play_arrow, 'Play', () {
                      _playSelectedAyah();
                      notifier.setShowAyahMenu(false);
                    }),
                    _buildMenuIcon(Icons.share, 'Share', () {
                      _shareAyah();
                      notifier.setShowAyahMenu(false);
                    }),
                    _buildMenuIcon(Icons.copy, 'Copy', () {
                      _copyAyahText();
                      notifier.setShowAyahMenu(false);
                    }),
                    _buildMenuIcon(Icons.note_add, 'Note', () {
                      _addNoteToAyah();
                      notifier.setShowAyahMenu(false);
                    }),
                    _buildMenuIcon(Icons.fullscreen, 'Translate', () {
                      notifier.setShowBars(false);
                      notifier.setShowAyahMenu(false);
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMenuIcon(IconData icon, String tooltip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  void _showAudioSettings(BuildContext context) {
    final quranState = ref.watch(quranProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext context) {
        String selectedReciter = quranState.selectedReciter;
        String selectedStartAyah = '0';
        String selectedEndAyah = '0';

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              // Wrap in SingleChildScrollView
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Audio Playback Options',
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedReciter,
                    decoration:
                    const InputDecoration(labelText: 'Choose Reciter'),
                    items: reciters
                        .map((reciter) => DropdownMenuItem(
                      value: reciter,
                      child: Text(
                        reciter,
                        style: TextStyle(fontFamily: 'SolaimanLipi'),
                      ),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setModalState(() => selectedReciter = val!);
                      _changeReciter(val!);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStartAyah,
                    decoration:
                    const InputDecoration(labelText: 'Choose Begin Ayah'),
                    items: List.generate(ayahTimings.length, (i) => '$i')
                        .map((ayah) => DropdownMenuItem(
                      value: ayah,
                      child: Text(
                        'আয়াত ${toBanglaNumber(int.parse(ayah) + 1)}',
                        style: TextStyle(
                          fontFamily: 'SolaimanLipi',
                        ),
                      ),
                    ))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedStartAyah = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedEndAyah,
                    decoration:
                    const InputDecoration(labelText: 'Choose End Ayah'),
                    items: List.generate(ayahTimings.length, (i) => '$i')
                        .map((ayah) => DropdownMenuItem(
                      value: ayah,
                      child: Text(
                        'আয়াত ${toBanglaNumber(int.parse(ayah) + 1)}',
                        style: TextStyle(
                          fontFamily: 'SolaimanLipi',
                        ),
                      ),
                    ))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedEndAyah = val!),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                    onPressed: () {
                      Navigator.pop(context);
                      final from = int.tryParse(selectedStartAyah) ?? 0;
                      final to = int.tryParse(selectedEndAyah) ?? from;
                      _playAyahs(from, to);
                    },
                  ),
                  const SizedBox(height: 20), // Add extra space at bottom
                ],
              ),
            );
          },
        );
      },
    );
  }
}

