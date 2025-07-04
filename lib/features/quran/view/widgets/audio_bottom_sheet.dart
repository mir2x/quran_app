import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    final suraNames = ref.watch(
      suraNamesProvider,
    ); // Assuming this provider exists

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
      // Scale padding using screenutil
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
      child: SingleChildScrollView(
        // <<< WRAP THE COLUMN WITH SingleChildScrollView
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // Keep min so it doesn't take infinite height when scrollable
          children: [
            // Add the Surah Selection Dropdown
            _labeledDropdown<String>(
              // Use String for display (Surah name)
              label: "সূরা",
              icon: HugeIcons.bulkRoundedBook01After,
              // Choose an appropriate icon
              // The value needs to be the *name* of the selected sura
              value: suraNames[selectedAudioSura - 1],
              // Get name of the currently selected audio sura
              items: suraNameOptions,
              // List of sura names
              onChanged: (val) {
                if (val != null) {
                  // Find the sura number corresponding to the selected name
                  final newSuraIndex = suraNames.indexOf(val);
                  if (newSuraIndex != -1) {
                    final newSuraNumber = newSuraIndex + 1;
                    // Update the selected audio sura provider state
                    ref.read(selectedAudioSuraProvider.notifier).state =
                        newSuraNumber;

                    // When sura changes, reset ayah selection to ayah 1
                    ref.read(selectedStartAyahProvider.notifier).state = 1;
                    ref.read(selectedEndAyahProvider.notifier).state = 1;
                  }
                }
              },
            ),
            // Scale height using .h
            SizedBox(height: 12.h),

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
            // Scale height using .h
            SizedBox(height: 12.h),
            _labeledDropdown<int>(
              label: "শুরু আয়াত",
              icon: HugeIcons.solidRoundedSquareArrowLeft03,
              value: startAyah,
              items: ayahOptions,
              onChanged: (val) {
                if (val != null) {
                  ref.read(selectedStartAyahProvider.notifier).state = val;
                }
                final currentEndAyah = ref.read(selectedEndAyahProvider);
                if (val != null && val > currentEndAyah) {
                  ref.read(selectedEndAyahProvider.notifier).state = val;
                }
              },
            ),
            // Scale height using .h
            SizedBox(height: 12.h),
            _labeledDropdown<int>(
              label: "শেষ আয়াত",
              icon: HugeIcons.solidRoundedSquareArrowRight03,
              value: endAyah.clamp(startAyah, lastAyah),
              items: ayahOptions.where((a) => a >= startAyah).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(selectedEndAyahProvider.notifier).state = val;
                }
              },
            ),
            // Scale height using .h
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              // Scale height of the button itself if needed,
              // but the padding/text size within the button are scaled below.
              // height: 50.h, // Example
              child: ElevatedButton.icon(
                icon: Icon(
                  HugeIcons.solidRoundedPlay,
                  // Scale icon size (Optional)
                  size: 24.r,
                ),
                label: Text(
                  'Play',
                  // Scale text within the button
                  style: TextStyle(fontSize: 16.sp),
                ),
                onPressed: () async {
                  final reciterId = ref.read(selectedReciterProvider);

                  final downloaded = await isAssetDownloaded(reciterId);

                  if (!downloaded) {
                    final reciter = ref
                        .read(reciterCatalogueProvider)
                        .firstWhere((r) => r.id == reciterId);

                    final confirmed = await downloadPermissionDialog(
                      context,
                      "audio",
                      reciterName: reciter.name,
                    );

                    if (!confirmed) return;

                    if (!context.mounted) return;
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext dialogContext) {
                        return DownloadDialog(
                          id: reciter.id,
                          zipUrl: reciter.zipUrl,
                          sizeBytes: reciter.sizeBytes,
                        );
                      },
                    );
                  }

                  if (!context.mounted) return;

                  final audioVM = ref.read(audioVMProvider);
                  if (audioVM.value == null || !audioVM.hasValue) {
                    await ref.read(audioVMProvider.notifier).loadTimings();
                  }

                  final playbackSura = ref.read(selectedAudioSuraProvider);
                  final from = ref.read(selectedStartAyahProvider);
                  final to = ref.read(selectedEndAyahProvider);
                  final service = ref.read(audioPlayerServiceProvider);

                  service.setCurrentSura(playbackSura);

                  int currentSuraLastAyah = 0;
                  if (playbackSura > 0 && playbackSura <= ayahCounts.length) {
                    currentSuraLastAyah = ayahCounts[playbackSura - 1];
                  } else {
                    debugPrint(
                      'Warning: Selected audio sura $playbackSura is out of bounds for ayahCounts',
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Invalid Surah selected for playback.',
                            // Optional: Scale snackbar text
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  final safeFrom = from.clamp(1, currentSuraLastAyah);
                  final safeTo = to.clamp(safeFrom, currentSuraLastAyah);

                  // Check if timing data is available for the selected surah and range
                  final timings = ref.read(audioVMProvider).value;
                  if (timings == null || timings.isEmpty) {
                    debugPrint('Error: Audio timings not loaded.');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Audio timings not loaded. Please try again.',
                            // Optional: Scale snackbar text
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  await service.playAyahs(safeFrom, safeTo);

                  // Check context again before popping
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
            // Scale height using .h
            SizedBox(height: 44.h),
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
      crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
      children: [
        Icon(
          icon,
          color: Colors.white,
          // Scale icon size
          size: 20.r,
        ),
        // Scale width using .w
        SizedBox(width: 8.w),
        Text(
          "$label:",
          style: TextStyle( // Remove const
            color: Colors.white,
            fontWeight: FontWeight.w600,
            // Scale font size
            fontSize: 16.sp, // Example size
          ),
        ),
        // Scale width using .w
        SizedBox(width: 12.w),
        Expanded(
          child: Container(
            // Scale padding using .w and .h
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h), // Added vertical padding for dropdown height
            decoration: BoxDecoration(
              color: const Color(0xFF294B39),
              border: Border.all(color: Colors.white24),
              // Scale border radius using .r
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isExpanded: true,
                value: value,
                dropdownColor: const Color(0xFF294B39),
                iconEnabledColor: Colors.white,
                style: TextStyle(color: Colors.white,
                  // Scale font size of dropdown items
                  fontSize: 16.sp, // Example size
                ),
                items: items.map((e) {
                  String itemText = e.toString();
                  return DropdownMenuItem<T>(
                    value: e,
                    child: Text(
                      itemText, // Use the potentially formatted text
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white,
                        // Scale font size of dropdown items (redundant if style is set on DropdownButton, but good practice)
                        fontSize: 16.sp, // Example size
                      ),
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