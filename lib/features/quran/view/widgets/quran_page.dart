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
    final allBoxesAsync = ref.watch(allBoxesProvider);
    // Watch the selected ayah state - this controls menu visibility
    final selectedState = ref.watch(selectedAyahProvider);
    final logicalPage = pageIndex + 1; // 1-based logical page number
    // Determine the page number to use for fetching boxes (handle intro pages)
    final pageNumber  = logicalPage < kFirstPageNumber ? -1 : logicalPage; // Use -1 for intro pages without boxes
    // Get the ayah boxes for this specific page (filtered by pageNumber)
    final boxes = pageNumber == -1 ? const <AyahBox>[] : ref.watch(boxesForPageProvider(pageNumber));
    // Get the notifier for updating selected ayah state
    final notifier = ref.read(selectedAyahProvider.notifier);
    // Get the image file for this page
    final imgFile = File('${editionDir.path}/qm${pageIndex + 1}.$imageExt');


    // --- Calculate Highlight Rects and Menu Anchor for THIS page ---
    List<Rect> highlightRectsOnThisPage = [];
    Rect? menuAnchorRectOnThisPage;

    // If an ayah is selected globally AND this page is a valid page with boxes
    if (selectedState != null && pageNumber != -1) {
      // Find ALL boxes on *this* page that belong to the selected (sura, ayah)
      final boxesForSelectedAyah = boxes.where(
            (box) =>
        box.suraNumber == selectedState.suraNumber &&
            box.ayahNumber == selectedState.ayahNumber,
      ).toList(); // Convert to list to iterate

      if (boxesForSelectedAyah.isNotEmpty) {
        // Get the size constraints provided by the LayoutBuilder (or parent)
        // Note: We need the actual rendered size to scale correctly.
        // The LayoutBuilder below provides this. Let's move the calculation
        // inside the LayoutBuilder's builder function to get correct constraints.
      }
    }
    // --- End Calculate Highlight Rects ---


    // Define the onTapDown logic for ayah selection
    // This function will be attached to a GestureDetector *within* the Stack,
    // potentially wrapped by an IgnorePointer.
    void onTapDown(TapDownDetails d, double scaleX, double scaleY, List<AyahBox> currentPageBoxes) {
      // If touch mode is off, handle the tap
      // The check for touch mode should be done *before* calling this function
      // or inside it, depending on where the GestureDetector is placed.
      // Since we'll put the GestureDetector here, check inside:
      if (!ref.read(touchModeProvider)) { // Only handle tap if touch mode is off
        final logicX = d.localPosition.dx / scaleX;
        final logicY = d.localPosition.dy / scaleY;
        // Find boxes on THIS page that contain the tap point
        final tappedBoxes = currentPageBoxes.where((b) => b.contains(logicX, logicY)).toList();

        if (tappedBoxes.isNotEmpty) {
          final tappedSura = tappedBoxes.first.suraNumber;
          final tappedAyah = tappedBoxes.first.ayahNumber;
          // Use the selectByTap method
          notifier.selectByTap(tappedSura, tappedAyah);
        } else {
          // If no box is tapped, clear the selection (hides the menu)
          notifier.clear();
        }
      }
      // If touch mode is on, the GestureDetector's onTapDown will be null,
      // or this logic won't execute.
    }


    return allBoxesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text(e.toString())),
      data:    (_) => LayoutBuilder( // Use LayoutBuilder to get the constraints for scaling
        builder: (_, constraints) {
          final scaleX = constraints.maxWidth  / imageWidth;
          final scaleY = constraints.maxHeight / imageHeight;

          // --- Recalculate Highlight Rects and Menu Anchor INSIDE LayoutBuilder ---
          List<Rect> highlightRectsOnThisPage = [];
          Rect? menuAnchorRectOnThisPage;

          // If an ayah is selected globally AND this page is a valid page with boxes
          if (selectedState != null && pageNumber != -1) {
            // Find ALL boxes on *this* page that belong to the selected (sura, ayah)
            final boxesForSelectedAyah = boxes.where(
                  (box) =>
              box.suraNumber == selectedState.suraNumber &&
                  box.ayahNumber == selectedState.ayahNumber,
            ).toList(); // Convert to list to iterate

            if (boxesForSelectedAyah.isNotEmpty) {
              // Calculate scaled rects for highlighting (potentially multiple for multi-line ayah)
              highlightRectsOnThisPage = boxesForSelectedAyah.map((box) {
                return Rect.fromLTWH(
                  box.minX * scaleX,
                  box.minY * scaleY,
                  box.width * scaleX,
                  box.height * scaleY,
                );
              }).toList();

              // Determine the anchor rect for the menu.
              // Find the box with the minimum boxId among those on this page that belong to the selected ayah.
              // Assumes boxId increments logically within a page for a given ayah.
              try {
                final firstBoxOnPageForSelectedAyah = boxesForSelectedAyah.reduce((a, b) => a.boxId < b.boxId ? a : b);

                menuAnchorRectOnThisPage = Rect.fromLTWH(
                  firstBoxOnPageForSelectedAyah.minX * scaleX,
                  firstBoxOnPageForSelectedAyah.minY * scaleY,
                  firstBoxOnPageForSelectedAyah.width * scaleX,
                  firstBoxOnPageForSelectedAyah.height * scaleY,
                );
              } catch (e) {
                // Handle case where reduce might fail (e.g., empty list, though checked by if)
                debugPrint("Error finding first box for selected ayah on page $pageNumber: $e");
                menuAnchorRectOnThisPage = null; // Ensure anchor is null on error
              }
            }
          }
          // --- End Recalculate Highlight Rects ---


          return Stack( // Removed the outer GestureDetector wrapping the Stack
            fit: StackFit.expand,
            children: [
              // Layer 1: The Quran Page Image
              Image.file(
                imgFile,
                fit: BoxFit.fill,
              ),

              // Layer 2: Ayah Highlighter (draws on top of the image)
              // Pass the calculated list of rects to the highlighter
              CustomPaint(
                painter: AyahHighlighter(highlightRectsOnThisPage), // Pass list of rects
              ),

              // Layer 3: GestureDetector for Ayah Selection Taps
              // This layer sits above the image and highlighter but below the Ayah Menu.
              // Use IgnorePointer to disable taps on this layer when the menu is visible.
              IgnorePointer(
                // Ignore taps on the page content layer when the Ayah Menu is shown
                // (which happens when an ayah is selected by tap source)
                ignoring: selectedState != null && selectedState.source == AyahSelectionSource.tap,
                child: GestureDetector(
                  // Use translucent behavior so taps on this layer are detected,
                  // but they pass through to widgets below if no specific widget
                  // on *this* layer consumes them (like a Container).
                  // However, since we want this GestureDetector to handle the *entire*
                  // page area for ayah selection, `HitTestBehavior.opaque` might also work,
                  // as long as the AyahMenu (which is on a higher layer) correctly
                  // consumes hits when it's visible. Let's stick with Opaque for the page area.
                  behavior: HitTestBehavior.opaque, // Make this layer's area hit-testable

                  // Attach the onTapDown logic here
                  // Pass necessary parameters to the handler
                  onTapDown: (details) => onTapDown(details, scaleX, scaleY, boxes),

                  // We don't need a child widget here if we just want to capture gestures over the area
                  // If you needed visual feedback or drawing on this layer, you could add a Container or CustomPaint.
                  child: Container(), // Use Container as a simple hit-target area
                ),
              ),


              // Layer 4: Ayah Menu (Positioned at the top based on anchorRect)
              // Show menu ONLY if source is tap AND we have a valid anchor rect on this page
              // The AyahMenu widget itself contains tappable buttons that will
              // consume the tap event before it reaches layers below.
              if (selectedState != null && selectedState.source == AyahSelectionSource.tap && menuAnchorRectOnThisPage != null)
                AyahMenu(anchorRect: menuAnchorRectOnThisPage!), // Use the calculated anchor rect
            ],
          );
        }, // <-- LayoutBuilder builder ends here
      ), // <-- LayoutBuilder ends here
    );
  }
}