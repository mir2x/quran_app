import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodel/ayah_highlight_viewmodel.dart';

class ParaNavigationView extends ConsumerWidget {
  const ParaNavigationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPara = ref.watch(selectedNavigationParaProvider);
    final paraPageRanges = ref.watch(paraPageRangesProvider);

    final allBoxesAsync = ref.watch(allBoxesProvider);
    final totalPageCountAsync = ref.watch(totalPageCountProvider);

    if (allBoxesAsync.isLoading || totalPageCountAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (allBoxesAsync.hasError) {
      return Center(child: Text('Error loading Para data: ${allBoxesAsync.error}'));
    }
    if (totalPageCountAsync.hasError) {
      return Center(child: Text('Error loading Page Count: ${totalPageCountAsync.error}'));
    }

    // Check if necessary mapping data is available after loading
    if (paraPageRanges.isEmpty && !allBoxesAsync.hasError && !totalPageCountAsync.hasError) {
      // If paraPageRanges is empty but no error/loading, it might mean no data was processed,
      // or mapping failed for all paras. For 30 paras, it should not be empty with valid data.
      return const Center(child: Text('Para page data not generated.'));
    }


    // Now build the UI based on selectedPara state
    if (selectedPara == null) {
      // Show list of all Paras - Pass ref to helper method
      return _buildParaList(ref, paraPageRanges);
    } else {
      // Show list of pages for the selected Para - Pass ref to helper method
      return _buildParaPageList(ref, selectedPara, paraPageRanges);
    }
  }

  // --- Helper methods moved here, now accepting WidgetRef as the first parameter ---

  Widget _buildParaList(WidgetRef ref, Map<int, List<int>> paraPageRanges) {
    // Check if data is missing (redundant if parent build handles, but safe)
    if (paraPageRanges.isEmpty) {
      return const Center(child: Text('Para data incomplete.'));
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
              // Optionally clear ayah highlight when switching navigation lists
              ref.read(selectedAyahProvider.notifier).clear();
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

  Widget _buildParaPageList(WidgetRef ref, int paraNumber, Map<int, List<int>> paraPageRanges) {
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
            // Optionally clear ayah highlight when going back to list
            ref.read(selectedAyahProvider.notifier).clear();
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
                  // Navigate to the selected page number (1-based)
                  ref.read(navigateToPageCommandProvider.notifier).state = pageNumber;
                  // No ayah highlighting needed here, just page navigation.
                  // Clear any existing ayah highlight if desired when navigating by page
                  ref.read(selectedAyahProvider.notifier).clear();
                  // Close the drawer after navigation
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}