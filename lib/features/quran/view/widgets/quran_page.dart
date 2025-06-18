import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/core/services/audio_service.dart'; // Assuming this path is correct
import '../../../../core/constants.dart'; // Assuming this path is correct
import '../../model/ayah_box.dart';
import '../../model/selected_ayah_state.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart'; // Assuming necessary providers are here
import 'ayah_highlighter.dart';
import 'ayah_menu.dart';

// Make sure you have the necessary providers and classes imported or defined elsewhere
// and accessible, e.g.:
// import 'path/to/your/providers.dart';
// (Includes allBoxesProvider, selectedAyahProvider, currentPageProvider,
// boxesForPageProvider, AyahSelectionSource, AyahBox, AyahMenu,
// AyahHighlighter, kFirstPageNumber, touchModeProvider)


class QuranPage extends ConsumerWidget {
  final int pageIndex;
  final Directory editionDir;
  final int imageWidth;
  final int imageHeight;
  final String imageExt;
  const QuranPage({
    super.key,
    required this.pageIndex,
    required this.editionDir,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageExt,
  });


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the necessary providers to trigger rebuilds when their state changes
    final allBoxesAsync = ref.watch(allBoxesProvider);
    final selectedState = ref.watch(selectedAyahProvider); // Watch the selected ayah state
    final touchModeOn = ref.watch(touchModeProvider); // Watch touch mode state

    final logicalPage = pageIndex + 1; // 1-based logical page number
    final pageNumber  = logicalPage < kFirstPageNumber ? -1 : logicalPage; // Use -1 for intro pages without boxes
    // Get the ayah boxes for this specific page (filtered by pageNumber)
    final boxes = pageNumber == -1 ? const <AyahBox>[] : ref.watch(boxesForPageProvider(pageNumber));
    // Get the notifier for updating selected ayah state
    final notifier = ref.read(selectedAyahProvider.notifier);
    // Get the image file for this page
    final imgFile = File('${editionDir.path}/qm${pageIndex + 1}.$imageExt');


    // Check if the currently selected ayah (if any) is on *this* page
    final bool isSelectedAyahOnThisPage = selectedState != null &&
        pageNumber != -1 &&
        boxes.any((box) => box.suraNumber == selectedState.suraNumber && box.ayahNumber == selectedState.ayahNumber);

    // Determine if the menu should be shown on *this* page
    // Menu is shown if an ayah is selected by tap source AND that ayah is on this page.
    final bool showMenuOnThisPage = selectedState != null &&
        selectedState.source == AyahSelectionSource.tap &&
        isSelectedAyahOnThisPage;


    // Define the onTapDown logic for ayah selection or clearing
    // This function will be attached to a GestureDetector covering the page area.
    void onTapDown(TapDownDetails d, double scaleX, double scaleY, List<AyahBox> currentPageBoxes) {

      // If an ayah is currently selected via a tap (meaning the menu is shown),
      // ANY tap on the page area should clear the selection and hide the menu.
      if (selectedState != null && selectedState.source == AyahSelectionSource.tap) {
        notifier.clear(); // Clear the selection state
        return; // Stop processing here, we just cleared.
      }

      // If no ayah is selected by tap (or selected by audio/navigation),
      // proceed with standard ayah selection logic IF touch mode is OFF.
      if (!touchModeOn) { // Only select a new ayah if touch mode is OFF
        final logicX = d.localPosition.dx / scaleX;
        final logicY = d.localPosition.dy / scaleY;
        // Find boxes on THIS page that contain the tap point
        final tappedBoxes = currentPageBoxes.where((b) => b.contains(logicX, logicY)).toList();

        if (tappedBoxes.isNotEmpty) {
          final tappedSura = tappedBoxes.first.suraNumber;
          final tappedAyah = tappedBoxes.first.ayahNumber;
          // Use the selectByTap method to select the new ayah
          notifier.selectByTap(tappedSura, tappedAyah);
        } else {
          // Tapped empty space when no tap-selected ayah existed. Do nothing.
          // If you wanted tapping empty space to clear other types of selections (audio/nav),
          // you would add notifier.clear() here, but the requirement was only
          // to clear tap selection by tapping anywhere.
        }
      }
      // If touch mode is ON, this onTapDown callback is still attached,
      // but the selection logic within the 'if (!touchModeOn)' block is skipped.
    }


    return allBoxesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text(e.toString())),
      data:    (_) => LayoutBuilder( // Use LayoutBuilder to get the constraints for scaling
        builder: (_, constraints) {
          final scaleX = constraints.maxWidth  / imageWidth;
          final scaleY = constraints.maxHeight / imageHeight;

          // --- Calculate Highlight Rects and Menu Anchor for THIS page ---
          List<Rect> highlightRectsOnThisPage = [];
          Rect? menuAnchorRectOnThisPage;

          // If an ayah is selected globally AND the selected ayah is on *this* page,
          // calculate its highlight rects and menu anchor.
          if (selectedState != null && isSelectedAyahOnThisPage) {

            // Find ALL boxes on *this* page that belong to the selected (sura, ayah)
            final boxesForSelectedAyah = boxes.where(
                  (box) =>
              box.suraNumber == selectedState.suraNumber &&
                  box.ayahNumber == selectedState.ayahNumber,
            ).toList();

            if (boxesForSelectedAyah.isNotEmpty) {
              // Calculate scaled rects for highlighting
              highlightRectsOnThisPage = boxesForSelectedAyah.map((box) {
                return Rect.fromLTWH(
                  box.minX * scaleX,
                  box.minY * scaleY,
                  box.width * scaleX,
                  box.height * scaleY,
                );
              }).toList();

              // Determine the anchor rect for the menu (usually the first box on the page)
              try {
                // Find the box with the minimum boxId among the selected ayah's boxes on this page
                final firstBoxOnPageForSelectedAyah = boxesForSelectedAyah.reduce((a, b) => a.boxId < b.boxId ? a : b);

                menuAnchorRectOnThisPage = Rect.fromLTWH(
                  firstBoxOnPageForSelectedAyah.minX * scaleX,
                  firstBoxOnPageForSelectedAyah.minY * scaleY,
                  firstBoxOnPageForSelectedAyah.width * scaleX,
                  firstBoxOnPageForSelectedAyah.height * scaleY,
                );
              } catch (e) {
                debugPrint("Error finding first box for selected ayah on page $pageNumber: $e");
                menuAnchorRectOnThisPage = null; // Ensure anchor is null on error
              }
            }
          }
          // --- End Calculate Highlight Rects ---


          return Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1: The Quran Page Image (Lowest layer)
              Image.file(
                imgFile,
                fit: BoxFit.fill,
              ),

              // Layer 2: Ayah Highlighter (Draws highlight on top of image)
              // It will draw the rects calculated above.
              CustomPaint(
                painter: AyahHighlighter(highlightRectsOnThisPage), // Pass list of rects
              ),

              // Layer 3: GestureDetector for Ayah Selection/Clearing Taps
              // This layer sits above the image and highlighter. It covers the whole page area.
              // It needs to be able to receive taps REGARDLESS of whether the menu is visible.
              GestureDetector(
                // `HitTestBehavior.translucent` or `opaque` can work here.
                // `opaque` makes the whole area consume hits, preventing hits
                // from going to layers *below* this one. This is what we want
                // for the page interaction area.
                behavior: HitTestBehavior.opaque,

                // Attach the onTapDown logic here.
                // Pass necessary parameters to the handler function.
                onTapDown: (details) => onTapDown(details, scaleX, scaleY, boxes),

                // No visible child needed for the GestureDetector itself
                child: Container(), // Simple invisible hit-target area
              ),


              // Layer 4: Ayah Menu (Highest layer - above everything else)
              // Show menu ONLY if the `showMenuOnThisPage` flag is true
              // AND we successfully calculated a valid anchor rect.
              if (showMenuOnThisPage && menuAnchorRectOnThisPage != null)
                AyahMenu(anchorRect: menuAnchorRectOnThisPage!), // Use the calculated anchor rect
            ],
          );
        }, // <-- LayoutBuilder builder ends here
      ), // <-- LayoutBuilder ends here
    );
  }
}