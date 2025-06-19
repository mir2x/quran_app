import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import screenutil

import '../../../../../core/theme.dart';
import '../../../viewmodel/ayah_highlight_viewmodel.dart';

class ParaNavigationView extends ConsumerWidget {
  const ParaNavigationView({super.key});

  // Helper function to convert Latin numbers to Bengali numbers (Keep this)
  String toBengaliNumber(int number) {
    const latinNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bengaliNumbers = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    String numberStr = number.toString();
    String bengaliStr = '';
    for (int i = 0; i < numberStr.length; i++) {
      int digit = int.parse(numberStr[i]);
      bengaliStr += bengaliNumbers[digit];
    }
    return bengaliStr;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPara = ref.watch(selectedNavigationParaProvider);
    final paraPageRanges = ref.watch(paraPageRangesProvider);

    final allBoxesAsync = ref.watch(allBoxesProvider);
    final totalPageCountAsync = ref.watch(totalPageCountProvider);

    if (allBoxesAsync.isLoading || totalPageCountAsync.isLoading) {
      return Center(child: CircularProgressIndicator()); // Remove const
    }
    if (allBoxesAsync.hasError) {
      return Center(child: Text(
        'Error loading Para data: ${allBoxesAsync.error}',
        style: TextStyle(fontSize: 14.sp), // Scale text
      )); // Remove const
    }
    if (totalPageCountAsync.hasError) {
      return Center(child: Text(
        'Error loading Page Count: ${totalPageCountAsync.error}',
        style: TextStyle(fontSize: 14.sp), // Scale text
      )); // Remove const
    }

    // Check if necessary mapping data is available after loading
    if (paraPageRanges.isEmpty && !allBoxesAsync.hasError && !totalPageCountAsync.hasError) {
      return Center(child: Text(
        'Para page data not generated.',
        style: TextStyle(fontSize: 14.sp), // Scale text
      )); // Remove const
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

  // --- Helper methods updated to use ScreenUtil and new color scheme ---

  Widget _buildParaList(WidgetRef ref, Map<int, List<int>> paraPageRanges) {
    // Check if data is missing (redundant if parent build handles, but safe)
    if (paraPageRanges.isEmpty) {
      return Center(child: Text(
        'Para data incomplete.',
        style: TextStyle(fontSize: 14.sp), // Scale text
      )); // Remove const
    }

    return ListView.separated( // Use ListView.separated for dividers
      padding: EdgeInsets.zero, // Remove default padding
      itemCount: 30, // There are 30 Paras
      // Use a light grey or subtle green for dividers on white background
      separatorBuilder: (context, index) => Divider(height: 1.h, color: Colors.grey.shade300), // Scaled divider
      itemBuilder: (context, index) {
        final paraNumber = index + 1;
        final pageNumbers = paraPageRanges[paraNumber]; // Get the list of pages

        // Display the first page number and the count of pages if available
        final String subtitleText;
        if (pageNumbers != null && pageNumbers.isNotEmpty) {
          final firstPage = toBengaliNumber(pageNumbers.first);
          final lastPage = toBengaliNumber(pageNumbers.last);
          final pageCount = toBengaliNumber(pageNumbers.length);
          subtitleText = 'পৃষ্ঠা $firstPage - $lastPage ($pageCount পৃষ্ঠা)'; // Formatted with Bengali numbers
        } else {
          subtitleText = 'পৃষ্ঠা তথ্য পাওয়া যায়নি';
        }

        return ListTile(
          // Use a custom leading widget for the Bengali number
          leading: Padding( // Add padding to align with Surah list leading
            padding: EdgeInsets.only(right: 8.w), // Scaled right padding
            child: Text(
              '${toBengaliNumber(paraNumber)}.', // Bengali number with dot
              style: TextStyle(
                fontSize: 14.sp, // Scale font size
                fontWeight: FontWeight.bold,
                // Use your primary green or a dark green for the number
                color: Theme.of(context).primaryColor, // Example: using primary color
              ),
            ),
          ),
          title: Text(
            'পারা ${toBengaliNumber(paraNumber)}', // Use Bengali number in title as well
            style: TextStyle(
              fontSize: 12.sp, // Scale font size
              // Use your primary green or a dark green for the Para label
              color: Theme.of(context).primaryColor, // Example: using primary color
            ),
          ),
          subtitle: Text(
            subtitleText,
            style: TextStyle(
              fontSize: 12.sp, // Scale font size
              // Use a darker grey or a less saturated green for the subtitle
              color: Colors.grey.shade700, // Example: dark grey
            ),
          ),
          // Add some horizontal padding to the content
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w), // Scaled horizontal padding
          onTap: () {
            // Select this para to show its pages
            if (pageNumbers != null && pageNumbers.isNotEmpty) {
              ref.read(selectedNavigationParaProvider.notifier).state = paraNumber;
              // Optionally clear ayah highlight when switching navigation lists
              ref.read(selectedAyahProvider.notifier).clear();
            } else {
              // Optionally show a message if no page data for this para
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                      'পৃষ্ঠা তথ্য পাওয়া যায়নি ${toBengaliNumber(paraNumber)}',
                      style: TextStyle(fontSize: 14.sp), // Scale text
                    )),
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
      return Center(child: Text(
        'Page data not found for this Para.',
        style: TextStyle(fontSize: 14.sp), // Scale text
      )); // Remove const
    }

    final paraName = "পারা ${toBengaliNumber(paraNumber)}"; // Placeholder with Bengali number

    return Column(
      children: [
        // Add a "Back" button at the top
        ListTile(
          leading: Icon(Icons.arrow_back, color: const Color(0xFF144910), size: 24.r), // Scale icon size, use primary color
          title: Text(
            paraName, // Title is the Para number with Bengali label
            style: TextStyle(
              fontSize: 18.sp, // Scale font size, slightly larger for header
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600, // Slightly lighter dark grey for the header text
            ),
          ),
          // Add some horizontal padding to the content
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w), // Scaled horizontal padding
          onTap: () {
            // Go back to the list of all paras
            ref.read(selectedNavigationParaProvider.notifier).state = null;
            // Optionally clear ayah highlight when going back to list
            ref.read(selectedAyahProvider.notifier).clear();
          },
        ),
        // Use a light grey or subtle green for the divider
        Divider(height: 1.h, color: Colors.grey.shade300), // Scaled divider

        Expanded(
          child: ListView.separated( // Use ListView.separated for dividers
            padding: EdgeInsets.zero, // Remove default padding
            // Use a light grey or subtle green for dividers
            separatorBuilder: (context, index) => Divider(height: 1.h, color: Colors.grey.shade300), // Scaled divider
            itemCount: pageNumbers.length,
            itemBuilder: (context, index) {
              final pageNumber = pageNumbers[index]; // Get the actual page number

              return ListTile(
                title: Text(
                  'পৃষ্ঠা ${toBengaliNumber(pageNumber)}', // Format with Bengali number
                  style: TextStyle(
                    fontSize: 12.sp, // Scale font size
                    // Use your primary green or a dark green for the page label
                    color: Theme.of(context).primaryColor, // Example: using primary color
                  ),
                ),
                // No trailing for Ayah list in Para pages view
                // onTap action navigates to the page
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w), // Scaled horizontal padding
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