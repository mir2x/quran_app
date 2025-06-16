import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/services/fileChecker.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart';
import '../../../../shared/downloader/download_dialog.dart';
import '../../../../shared/downloader/download_permission_dialog.dart';

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
      return suraNames[suraNum - 1]; // Get name from 0-indexed list
    }).toList();


    return Container(
      color: const Color(0xFF294B39),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                // Ensure end ayah is not less than start ayah
                if (val > ref.read(selectedEndAyahProvider)) { // Read current endAyah state
                  ref.read(selectedEndAyahProvider.notifier).state = val;
                }
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

                  final confirmed =
                  await downloadPermissionDialog(context, "audio", reciterName: reciter.name);

                  if (!confirmed) return;

                  // Check if context is still valid before showing dialog
                  if (!context.mounted) return;
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => DownloadDialog(id: reciter.id, zipUrl: reciter.zipUrl, sizeBytes: reciter.sizeBytes),
                  );
                }

                // Check if context is still valid after download/dialog
                if (!context.mounted) return;

                // Step 3: Load timing after download
                // Ensure timing data is loaded for the *selected* reciter
                await ref.read(audioVMProvider.notifier).loadTimings(); // This method should use the currently selectedReciterProvider state


                // Step 4: Proceed with playback
                final playbackSura = ref.read(selectedAudioSuraProvider); // Get the selected audio sura
                final from = ref.read(selectedStartAyahProvider);
                final to = ref.read(selectedEndAyahProvider);
                final service = ref.read(audioPlayerServiceProvider);

                // Pass the selected playbackSura to the service
                service.setCurrentSura(playbackSura);

                // Ensure start and end ayahs are within the bounds of the selected sura
                final currentSuraLastAyah = ayahCounts[playbackSura - 1];
                final safeFrom = from.clamp(1, currentSuraLastAyah);
                final safeTo = to.clamp(safeFrom, currentSuraLastAyah);


                await service.playAyahs(safeFrom, safeTo);

                // Check context again before popping
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Keep the _labeledDropdown method as is
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