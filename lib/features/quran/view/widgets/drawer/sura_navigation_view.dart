import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodel/ayah_highlight_viewmodel.dart';

class SurahNavigationView extends ConsumerWidget {
  const SurahNavigationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSurah = ref.watch(selectedNavigationSurahProvider);
    final suraMapping = ref.watch(suraPageMappingProvider);
    final ayahCounts = ref.watch(ayahCountsProvider);
    final suraNames = ref.watch(suraNamesProvider);
    final ayahPageMapping = ref.watch(ayahPageMappingProvider);

    final allBoxesAsync = ref.watch(allBoxesProvider);

    if (allBoxesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (allBoxesAsync.hasError) {
      return Center(child: Text('Error loading Surah/Ayah data: ${allBoxesAsync.error}'));
    }

    if (suraMapping.isEmpty || ayahCounts.isEmpty || suraNames.length < 114 || ayahPageMapping.isEmpty) {
      return const Center(child: Text('Data not fully loaded or incomplete.'));
    }


    if (selectedSurah == null) {
      return _buildSurahList(ref, suraMapping, ayahCounts, suraNames);
    } else {
      return _buildAyahListForSurah(ref, selectedSurah, ayahCounts, suraNames, ayahPageMapping);
    }
  }


  Widget _buildSurahList(WidgetRef ref, Map<int, int> suraMapping, List<int> ayahCounts, List<String> suraNames) {
    if (suraNames.length < 114 || ayahCounts.length < 114 || suraMapping.isEmpty) {
      return const Center(child: Text('Internal data incomplete.'));
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
            ref.read(selectedNavigationSurahProvider.notifier).state = suraNumber;
          },
        );
      },
    );
  }

  Widget _buildAyahListForSurah(WidgetRef ref, int suraNumber, List<int> ayahCounts, List<String> suraNames, Map<(int, int), int> ayahPageMapping) {
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
          leading: const Icon(Icons.arrow_back),
          title: Text('$surahName'), // Use the surah name as the title
          onTap: () {
            // Go back to the list of all surahs
            ref.read(selectedNavigationSurahProvider.notifier).state = null;
            // Optionally clear any existing highlight when going back to surah list
            ref.read(selectedAyahProvider.notifier).clear();
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
}