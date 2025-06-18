import 'dart:io'; // Might not be needed here, check imports
import 'dart:math' as math; // Might not be needed here, check imports

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../model/bookmark.dart'; // Assuming this exists
import '../../viewmodel/ayah_highlight_viewmodel.dart'; // Assuming this exists and contains necessary providers/definitions like reciters, touchModeProvider, selectedAyahProvider, OrientationToggle, quranInfoServiceProvider, bookmarkProvider, selectedReciterProvider, currentSuraProvider, currentPageProvider
import '../../viewmodel/bookmark_viewmodel.dart'; // Assuming this contains bookmarkProvider and BookmarkNotifier (with isPageBookmarked)
import 'audio_bottom_sheet.dart'; // Assuming this exists


class BottomBar extends ConsumerWidget {
  final bool drawerOpen;
  final GlobalKey<ScaffoldState> rootKey;

  const BottomBar({super.key, required this.drawerOpen, required this.rootKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedReciter = ref.watch(selectedReciterProvider);
    // Ensure reciters map is accessible, maybe it's in ayah_highlight_viewmodel.dart
    final displayReciterName = reciters.entries
        .firstWhere((e) => e.value == selectedReciter)
        .key;

    // Watch the current page number (1-based)
    final currentPage = ref.watch(currentPageProvider) + 1;
    // Read the bookmark notifier
    final bookmarkNotifier = ref.read(bookmarkProvider.notifier);
    // Watch the bookmark provider to rebuild when bookmarks change
    final bookmarksAsync = ref.watch(bookmarkProvider); // Watch the AsyncValue


    // Determine if the current page is bookmarked
    final bool isPageBookmarked = bookmarkNotifier.isPageBookmarked(currentPage);


    // Replace BottomAppBar with a Container or SizedBox
    return Container( // Changed from BottomAppBar
      height: 64, // Set the desired height
      color: const Color(0xFF294B39), // Set the background color
      // Remove padding here, let the Row manage its internal spacing
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Vertically center children in the Row
        children: [
          _iconBtn(
            icon: HugeIcons.solidRoundedPlay,
            onPressed: () {
              // Ensure currentSuraProvider and currentPageProvider are accessible
              final sura = ref.watch(currentSuraProvider);
              // The page variable here seems unused in the modal logic, keeping it for now
              final page = ref.watch(currentPageProvider); // This is 0-based index
              debugPrint('Current Sura: $sura');
              debugPrint('Current Page (0-based): $page');


              showModalBottomSheet(
                context: context,
                // Ensure the modal bottom sheet is shown outside the GestureDetector/Stack
                // context: rootKey.currentContext ?? context, // Use root context if available
                // Use a builder that provides a ScaffoldMessenger context
                builder: (BuildContext context) {
                  // Pass the 1-based sura to the bottom sheet
                  return AudioBottomSheet(currentSura: ref.read(currentSuraProvider));
                },
                // Set isScrollControlled to true if the content can take up more than half the screen
                // isScrollControlled: true,
              );
            },
          ),

          Expanded(
            child: Container(
              height: 40, // Give the dropdown container a specific height
              margin: const EdgeInsets.symmetric(vertical: 12), // Use margin for space around it
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF294B39),
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: const Color(0xFF294B39),
                  iconEnabledColor: Colors.white,
                  style: const TextStyle(color: Colors.white),
                  value: displayReciterName,
                  items: reciters.keys.map((displayName) {
                    return DropdownMenuItem(
                      value: displayName,
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
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
          const SizedBox(width: 5), // Space between dropdown and next icon
          Consumer(
            builder: (_, ref, __) {
              // Ensure touchModeProvider and selectedAyahProvider are accessible
              final on = ref.watch(touchModeProvider);
              return _iconBtn(
                icon: HugeIcons.solidStandardTouchLocked04, // Assuming HugeIcons is imported
                color: on ? Colors.orangeAccent : Colors.white,
                size: 26,
                onPressed: () {
                  ref.read(touchModeProvider.notifier).toggle();
                  if (!ref.read(touchModeProvider)) {
                    // Clear selected ayah only if touch mode is turned OFF
                    ref.read(selectedAyahProvider.notifier).clear();
                  }
                },
              );
            },
          ),
          // Ensure OrientationToggle is accessible
          _iconBtn(
            icon: HugeIcons.solidSharpScreenRotation, // Assuming HugeIcons is imported
            onPressed: () => OrientationToggle.toggle(),
          ),
          // Bookmark Button (Enhanced)
          _iconBtn(
            // Icon changes based on bookmark status
            icon: isPageBookmarked ? HugeIcons.solidStandardStackStar : HugeIcons.strokeStandardStackStar,
            // Color changes based on bookmark status
            color: isPageBookmarked ? Colors.orangeAccent : Colors.white,
            onPressed: () {
              // Ensure context is valid
              if (!context.mounted) return;

              // Use 1-based page number
              final pageToBookmark = ref.read(currentPageProvider) + 1;
              final identifier = 'page-$pageToBookmark'; // Unique identifier for page bookmark

              // Use the bookmarked status determined earlier
              if (isPageBookmarked) {
                // Remove bookmark
                bookmarkNotifier.remove(identifier);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('পৃষ্ঠা বুকমার্ক থেকে সরানো হয়েছে')), // Bengali message for removed
                );
              } else {
                // Add bookmark
                // Ensure quranInfoServiceProvider is accessible
                final quranInfoService = ref.read(quranInfoServiceProvider);

                // Get representative Sura and Para for the page using the service
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
                  // Show confirmation message in Bengali
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('পৃষ্ঠা বুকমার্ক করা হয়েছে')), // Bengali message for added
                  );
                } else {
                  // Handle case where sura or para could not be determined for the page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('এই পৃষ্ঠার জন্য সূরা/পারা নির্ধারণ করা যায়নি')), // Bengali message for error
                  );
                }
              }
            },
          ),
          // Example of an unused button, can remove or replace
          // _iconBtn(icon: HugeIcons.solidRoundedArrowExpand, onPressed: (){})

          // Example of the old drawer toggle button (can be removed if no longer needed here)
          _iconBtn(
            icon: HugeIcons.solidRoundedNavigation01,
            onPressed: () {
              if (drawerOpen) { // Check the state from the provider
                rootKey.currentState?.closeDrawer(); // Use rootKey to close
              } else {
                rootKey.currentState?.openDrawer(); // Use rootKey to open
              }
            },
          ),
        ],
      ),
    );
  }

  // Helper widget function for creating icon buttons
  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onPressed,
    double? size,
    Color color = Colors.white,
  }) {
    return IconButton(
      iconSize: size ?? 24,
      constraints: const BoxConstraints(minHeight: 64, minWidth: 48), // Ensure consistent tap area
      padding: EdgeInsets.zero, // Remove padding within the button itself
      icon: Center(child: Icon(icon, color: color)), // Center the icon visually
      onPressed: onPressed,
    );
  }
}