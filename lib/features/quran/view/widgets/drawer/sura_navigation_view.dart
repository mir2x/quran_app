import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import screenutil
import 'package:quran/quran.dart' as quran; // Import the quran package for Arabic names if needed
import '../../../viewmodel/ayah_highlight_viewmodel.dart';

class SurahNavigationView extends ConsumerWidget {
  const SurahNavigationView({super.key});

  // Helper function to convert Latin numbers to Bengali numbers
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
    final selectedSurah = ref.watch(selectedNavigationSurahProvider);
    final suraMapping = ref.watch(suraPageMappingProvider);
    final ayahCounts = ref.watch(ayahCountsProvider);
    final suraNames = ref.watch(suraNamesProvider);
    final ayahPageMapping = ref.watch(ayahPageMappingProvider);

    final allBoxesAsync = ref.watch(allBoxesProvider);

    if (allBoxesAsync.isLoading) {
      return Center(child: CircularProgressIndicator()); // Remove const
    }
    if (allBoxesAsync.hasError) {
      return Center(child: Text(
        'Error loading Surah/Ayah data: ${allBoxesAsync.error}',
        style: TextStyle(fontSize: 14.sp), // Scale text
      )); // Remove const
    }

    // Data validation checks
    if (suraMapping.isEmpty || ayahCounts.length < 114 || suraNames.length < 114 || ayahPageMapping.isEmpty) {
      // Improved loading/data check message
      return Center(child: Text(
        'Loading or data incomplete. Please wait...',
        style: TextStyle(fontSize: 14.sp), // Scale text
      ));
    }

    if (selectedSurah == null) {
      // Pass necessary data to the build method
      return _buildSurahList(ref, suraMapping, ayahCounts, suraNames);
    } else {
      // Pass necessary data to the build method
      return _buildAyahListForSurah(ref, selectedSurah, ayahCounts, suraNames, ayahPageMapping);
    }
  }

  Widget _buildSurahList(WidgetRef ref, Map<int, int> suraMapping, List<int> ayahCounts, List<String> suraNames) {
    // Re-validate data within the build method for robustness
    if (suraNames.length < 114 || ayahCounts.length < 114 || suraMapping.isEmpty) {
      return Center(child: Text('Internal data incomplete for Surah list.'));
    }


    return ListView.separated( // Use ListView.separated for dividers
      padding: EdgeInsets.zero, // Remove default padding
      itemCount: 114,
      separatorBuilder: (context, index) => Divider(height: 1.h, color: Colors.white24), // Scaled divider
      itemBuilder: (context, index) {
        final suraNumber = index + 1;
        final startPage = suraMapping[suraNumber];
        final totalAyahs = ayahCounts[index];
        final surahName = suraNames[index]; // Get the Bengali name

        // Optional: Get the Arabic name if you want to display both
        // final arabicSurahName = quran.getSurahNameArabic(suraNumber);

        return ListTile(
          // Use a custom leading widget for number and Arabic name
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
            children: [
              Text(
                '${toBengaliNumber(suraNumber)}.', // Bengali number with dot
                style: TextStyle(
                  fontSize: 16.sp, // Scale font size
                  fontWeight: FontWeight.bold,
                  color: Colors.black54, // Set text color
                ),
              ),
              // Optional: Add Arabic name here
              // Text(
              //   arabicSurahName,
              //   style: TextStyle(
              //     fontSize: 14.sp, // Scale font size
              //     fontFamily: 'Quran', // Assuming you have a Quran font
              //     color: Colors.white70, // Lighter color for Arabic
              //   ),
              // ),
            ],
          ),
          // Use the Bengali name as the title
          title: Text(
            surahName,
            style: TextStyle(
              fontSize: 16.sp, // Scale font size
              color: Colors.grey.shade700, // Set text color
            ),
          ),
          // Format subtitle with Bengali numbers and labels
          subtitle: Text(
            'আয়াত সংখ্যাঃ ${toBengaliNumber(totalAyahs)}${startPage != null ? ', শুরুঃ পৃষ্ঠা ${toBengaliNumber(startPage)}' : ''}',
            style: TextStyle(
              fontSize: 12.sp, // Scale font size
              color: Colors.black38, // Slightly lighter color for subtitle
            ),
          ),
          // Add some horizontal padding to the content
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w), // Scaled horizontal padding
          onTap: () {
            ref.read(selectedNavigationSurahProvider.notifier).state = suraNumber;
          },
        );
      },
    );
  }

  Widget _buildAyahListForSurah(WidgetRef ref, int suraNumber, List<int> ayahCounts, List<String> suraNames, Map<(int, int), int> ayahPageMapping) {
    // Re-validate data within the build method for robustness
    if (suraNumber < 1 || suraNumber > 114) {
      return const Center(child: Text('Invalid Surah number.'));
    }
    if (ayahCounts.length < suraNumber || suraNames.length < suraNumber) {
      return const Center(child: Text('Ayah count or name data incomplete.'));
    }

    final totalAyahs = ayahCounts[suraNumber - 1];
    final surahName = suraNames[suraNumber - 1];

    return Column(
      children: [
        // Add a "Back" button at the top
        ListTile(
          leading: Icon(Icons.arrow_back, color: const Color(0xFF144910), size: 24.r), // Scale icon size
          title: Text(
            surahName, // Use the surah name as the title
            style: TextStyle(
              fontSize: 18.sp, // Scale font size, slightly larger for header
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          // Add some horizontal padding to the content
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w), // Scaled horizontal padding
          onTap: () {
            // Go back to the list of all surahs
            ref.read(selectedNavigationSurahProvider.notifier).state = null;
            // Optionally clear any existing highlight when going back to surah list
            ref.read(selectedAyahProvider.notifier).clear();
          },
        ),
        Divider(height: 1.h, color: Colors.grey.shade300), // Scaled divider - Light grey on white

        Expanded(
          child: ListView.separated( // Use ListView.separated for dividers
            padding: EdgeInsets.zero, // Remove default padding
            separatorBuilder: (context, index) => Divider(height: 1.h, color: Colors.grey.shade300), // Scaled divider - Light grey on white
            itemCount: totalAyahs,
            itemBuilder: (context, index) {
              final ayahNumber = index + 1;
              // Get the page number for this specific Ayah
              final targetPage = ayahPageMapping[(suraNumber, ayahNumber)];

              return ListTile(
                title: Text(
                  'আয়াত ${toBengaliNumber(ayahNumber)}', // Format with Bengali number
                  style: TextStyle(
                    fontSize: 14.sp, // Scale font size
                    color: Theme.of(context).primaryColor, // Suggestion: Your primary green for the label
                  ),
                ),
                trailing: targetPage != null
                    ? Text(
                  'পৃষ্ঠা ${toBengaliNumber(targetPage)}', // Format with Bengali number
                  style: TextStyle(
                    fontSize: 12.sp, // Scale font size
                    color: Colors.grey.shade600, // Suggestion: Dark grey for the page number
                  ),
                )
                    : Text('N/A', style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)), // Scale N/A text and use dark grey
                // Add some horizontal padding to the content
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w), // Scaled horizontal padding
                onTap: () {
                  if (targetPage != null) {
                    // Navigate to the page (1-based page number)
                    ref.read(navigateToPageCommandProvider.notifier).state = targetPage;

                    // Update the selected ayah provider for highlighting
                    // Use the selectByNavigation method from the refactored notifier
                    ref.read(selectedAyahProvider.notifier).selectByNavigation(suraNumber, ayahNumber);

                    // Close the drawer after navigation
                    Navigator.of(context).pop();
                  } else {
                    // Handle case where ayah page is not found
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                            'Page data not found for this Ayah',
                            style: TextStyle(fontSize: 14.sp), // Scale text
                          )),
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
}