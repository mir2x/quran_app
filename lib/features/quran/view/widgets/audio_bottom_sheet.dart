import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/services/fileChecker.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart';
import '../../../../shared/downloader/download_dialog.dart';
import '../../../../shared/downloader/download_permission_dialog.dart';

// Make sure you have the necessary providers and classes imported or defined elsewhere
// and accessible, e.g.:
// import 'path/to/your/providers.dart';
// (Includes ayahCountsProvider, suraNamesProvider, selectedAudioSuraProvider,
// selectedReciterProvider, selectedStartAyahProvider, selectedEndAyahProvider,
// reciters, reciterCatalogueProvider, isAssetDownloaded, downloadPermissionDialog,
// audioVMProvider, audioPlayerServiceProvider, AudioControllerService, Bookmark,
// OrientationToggle, QuranInfoService, BarsVisibilityNotifier, barsVisibilityProvider,
// AudioBottomSheet, QuranAudioState)


class AudioBottomSheet extends ConsumerStatefulWidget {
  final int currentSura; // This is the sura of the currently viewed page

  const AudioBottomSheet({super.key, required this.currentSura});

  @override
  ConsumerState<AudioBottomSheet> createState() => _AudioBottomSheetState();
}

class _AudioBottomSheetState extends ConsumerState<AudioBottomSheet> {

  @override
  void initState() {
    super.initState();
    // Set the initial value of the selected audio sura provider
    // based on the sura of the page currently being viewed.
    Future.microtask(() {
      ref.read(selectedAudioSuraProvider.notifier).state = widget.currentSura;
    });
  }


  @override
  Widget build(BuildContext context) {
    // Watch the new selected audio sura provider
    final selectedAudioSura = ref.watch(selectedAudioSuraProvider);

    final selectedReciter = ref.watch(selectedReciterProvider);
    final startAyah = ref.watch(selectedStartAyahProvider);
    final endAyah = ref.watch(selectedEndAyahProvider);

    // Watch the ayah counts and sura names providers
    final ayahCounts = ref.watch(ayahCountsProvider);
    final suraNames = ref.watch(suraNamesProvider); // Assuming this provider exists

    // Calculate last ayah based on the *selected audio sura*
    final lastAyah = ayahCounts[selectedAudioSura - 1];
    final ayahOptions = List.generate(lastAyah, (i) => i + 1);

    // Generate Surah options (1 to 114)
    final suraOptions = List.generate(114, (i) => i + 1);
    // Map Surah numbers to names for display
    final suraNameOptions = suraOptions.map((suraNum) {
      // Safely access sura name, handle potential index out of bounds defensively
      if (suraNum > 0 && suraNum <= suraNames.length) {
        return suraNames[suraNum - 1]; // Get name from 0-indexed list
      }
      return 'Surah $suraNum'; // Fallback if name not found
    }).toList();


    return Container(
      color: const Color(0xFF294B39),
      // Use symmetric padding instead of fromLTRB if you want consistent top/bottom padding
      // Or keep fromLTRB if specific values are desired
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: SingleChildScrollView( // <<< WRAP THE COLUMN WITH SingleChildScrollView
        child: Column(
          mainAxisSize: MainAxisSize.min, // Keep min so it doesn't take infinite height when scrollable
          children: [
            // Add the Surah Selection Dropdown
            _labeledDropdown<String>( // Use String for display (Surah name)
              label: "সূরা",
              icon: HugeIcons.bulkRoundedBook01After, // Choose an appropriate icon
              // The value needs to be the *name* of the selected sura
              value: suraNames[selectedAudioSura - 1], // Get name of the currently selected audio sura
              items: suraNameOptions, // List of sura names
              onChanged: (val) {
                if (val != null) {
                  // Find the sura number corresponding to the selected name
                  final newSuraIndex = suraNames.indexOf(val);
                  if (newSuraIndex != -1) {
                    final newSuraNumber = newSuraIndex + 1;
                    // Update the selected audio sura provider state
                    ref.read(selectedAudioSuraProvider.notifier).state = newSuraNumber;

                    // When sura changes, reset ayah selection to ayah 1
                    ref.read(selectedStartAyahProvider.notifier).state = 1;
                    ref.read(selectedEndAyahProvider.notifier).state = 1;
                  }
                }
              },
            ),
            const SizedBox(height: 12),

            _labeledDropdown(
              label: "ক্বারী",
              icon: HugeIcons.solidStandardMuslim,
              value: reciters.entries
                  .firstWhere((e) => e.value == selectedReciter)
                  .key,
              items: reciters.keys.toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(selectedReciterProvider.notifier).state =
                  reciters[val]!;
                }
              },
            ),
            const SizedBox(height: 12),
            _labeledDropdown<int>(
              label: "শুরু আয়াত",
              icon: HugeIcons.solidRoundedSquareArrowLeft03,
              value: startAyah,
              // Items are now based on the *selected audio sura*'s ayah count
              items: ayahOptions,
              onChanged: (val) {
                if (val != null) {
                  ref.read(selectedStartAyahProvider.notifier).state = val;
                }
                // Ensure end ayah is not less than start ayah AFTER updating startAyah
                // Read current endAyah state *again* after potential state update above
                final currentEndAyah = ref.read(selectedEndAyahProvider);
                if (val != null && val > currentEndAyah) {
                  ref.read(selectedEndAyahProvider.notifier).state = val;
                }
              },
            ),
            const SizedBox(height: 12),
            _labeledDropdown<int>(
              label: "শেষ আয়াত",
              icon: HugeIcons.solidRoundedSquareArrowRight03,
              // Value should be clamped to the available options for the selected start ayah
              value: endAyah.clamp(startAyah, lastAyah), // Clamp the value
              // Items are now based on the *selected audio sura*'s ayah count AND the selected start ayah
              items: ayahOptions.where((a) => a >= startAyah).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(selectedEndAyahProvider.notifier).state = val;
                }
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(HugeIcons.solidRoundedPlay),
                label: const Text('Play'),
                onPressed: () async {
                  final reciterId = ref.read(selectedReciterProvider);

                  // Step 1: Check if downloaded
                  final downloaded = await isAssetDownloaded(reciterId);

                  if (!downloaded) {
                    final reciter = ref.read(reciterCatalogueProvider)
                        .firstWhere((r) => r.id == reciterId);

                    // Use the context argument passed to onPressed's builder
                    final confirmed =
                    await downloadPermissionDialog(context, "audio", reciterName: reciter.name);

                    if (!confirmed) return;

                    // Check if context is still valid before showing dialog
                    if (!context.mounted) return;
                    await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext dialogContext) { // Use a new context for the dialog
                          return DownloadDialog(id: reciter.id, zipUrl: reciter.zipUrl, sizeBytes: reciter.sizeBytes);
                        }
                    );
                  }

                  // Check if context is still valid after download/dialog
                  if (!context.mounted) return;

                  // Step 3: Load timing after download
                  // Ensure timing data is loaded for the *selected* reciter
                  // audioVMProvider depends on selectedReciterProvider,
                  // so loading the timings for the current state should be automatic
                  // when the provider is first accessed or its dependencies change.
                  // You might need to explicitly call loadTimings() only if
                  // the audioVMProvider's build method doesn't automatically
                  // trigger loading based on selectedReciterProvider changes.
                  final audioVM = ref.read(audioVMProvider); // Read the current state/notifier
                  if (audioVM.value == null || !audioVM.hasValue) { // Check if timings are already loaded
                    await ref.read(audioVMProvider.notifier).loadTimings(); // Explicitly load if not
                  }


                  // Step 4: Proceed with playback
                  final playbackSura = ref.read(selectedAudioSuraProvider); // Get the selected audio sura
                  final from = ref.read(selectedStartAyahProvider);
                  final to = ref.read(selectedEndAyahProvider);
                  final service = ref.read(audioPlayerServiceProvider);

                  // Pass the selected playbackSura to the service
                  service.setCurrentSura(playbackSura);

                  // Ensure start and end ayahs are within the bounds of the selected sura
                  // Safely access ayah counts list
                  int currentSuraLastAyah = 0;
                  if (playbackSura > 0 && playbackSura <= ayahCounts.length) {
                    currentSuraLastAyah = ayahCounts[playbackSura - 1];
                  } else {
                    debugPrint('Warning: Selected audio sura $playbackSura is out of bounds for ayahCounts');
                    // Handle error or default behavior
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid Surah selected for playback.')),
                      );
                    }
                    return; // Stop playback attempt
                  }

                  final safeFrom = from.clamp(1, currentSuraLastAyah);
                  final safeTo = to.clamp(safeFrom, currentSuraLastAyah);

                  // Check if timing data is available for the selected surah and range
                  final timings = ref.read(audioVMProvider).value;
                  if (timings == null || timings.isEmpty) {
                    debugPrint('Error: Audio timings not loaded.');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Audio timings not loaded. Please try again.')),
                      );
                    }
                    return; // Stop playback attempt
                  }
                  // Optional: Add a check if timings exist for the specific sura/ayahs

                  await service.playAyahs(safeFrom, safeTo);

                  // Check context again before popping
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 44),
            // Add extra padding at the bottom if needed to ensure the last item
            // is not covered by the keyboard or system gestures area.
            // MediaQuery.of(context).viewInsets.bottom provides keyboard height.
            // MediaQuery.of(context).padding.bottom provides safe area bottom padding.
            // You might want to add the maximum of these or just a fixed padding.
            // const SizedBox(height: 16), // Example extra padding
            // Or dynamic padding: SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _labeledDropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          "$label:",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF294B39),
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isExpanded: true,
                value: value,
                dropdownColor: const Color(0xFF294B39),
                iconEnabledColor: Colors.white,
                style: const TextStyle(color: Colors.white),
                items: items.map((e) {
                  // Handle item text based on type if needed (e.g., for Surah names)
                  String itemText = e.toString();
                  // If T is int (for ayahs), just use toString()
                  // If T is String (for surah names), use the string directly

                  return DropdownMenuItem<T>(
                    value: e,
                    child: Text(
                      itemText, // Use the potentially formatted text
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}