import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../viewmodel/audio_providers.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart';
import '../../viewmodel/reciter_providers.dart';


class AudioBottomSheet extends ConsumerStatefulWidget {
  final int currentSura;

  const AudioBottomSheet({super.key, required this.currentSura});

  @override
  ConsumerState<AudioBottomSheet> createState() => _AudioBottomSheetState();
}

class _AudioBottomSheetState extends ConsumerState<AudioBottomSheet> {
  @override
  void initState() {
    super.initState();
       Future.microtask(() {
      ref.read(selectedAudioSuraProvider.notifier).state = widget.currentSura;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedAudioSura = ref.watch(selectedAudioSuraProvider);
    final selectedReciter = ref.watch(selectedReciterProvider);
    final startAyah = ref.watch(selectedStartAyahProvider);
    final endAyah = ref.watch(selectedEndAyahProvider);
    final ayahCounts = ref.watch(ayahCountsProvider);
    final suraNames = ref.watch(suraNamesProvider);

    final lastAyah = ayahCounts[selectedAudioSura - 1];
    final ayahOptions = List.generate(lastAyah, (i) => i + 1);
    final suraNameOptions = suraNames;

    return Container(
      color: const Color(0xFF294B39),
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- The dropdown widgets are unchanged ---
            _labeledDropdown<String>(
              label: "সূরা",
              icon: HugeIcons.bulkRoundedBook01After,
              value: suraNames[selectedAudioSura - 1],
              items: suraNameOptions,
              onChanged: (val) {
                if (val != null) {
                  final newSuraIndex = suraNames.indexOf(val);
                  if (newSuraIndex != -1) {
                    final newSuraNumber = newSuraIndex + 1;
                    ref.read(selectedAudioSuraProvider.notifier).state = newSuraNumber;
                    // Reset ayah selection when surah changes
                    ref.read(selectedStartAyahProvider.notifier).state = 1;
                    ref.read(selectedEndAyahProvider.notifier).state = 1;
                  }
                }
              },
            ),
            SizedBox(height: 12.h),
            _labeledDropdown<String>(
              label: "ক্বারী",
              icon: HugeIcons.solidStandardMuslim,
              value: reciters.entries.firstWhere((e) => e.value == selectedReciter).key,
              items: reciters.keys.toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(selectedReciterProvider.notifier).state = reciters[val]!;
                }
              },
            ),
            SizedBox(height: 12.h),
            _labeledDropdown<int>(
              label: "শুরু আয়াত",
              icon: HugeIcons.solidRoundedSquareArrowLeft03,
              value: startAyah.clamp(1, lastAyah), // Clamp for safety
              items: ayahOptions,
              onChanged: (val) {
                if (val != null) {
                  ref.read(selectedStartAyahProvider.notifier).state = val;
                  final currentEndAyah = ref.read(selectedEndAyahProvider);
                  if (val > currentEndAyah) {
                    ref.read(selectedEndAyahProvider.notifier).state = val;
                  }
                }
              },
            ),
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
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(HugeIcons.solidRoundedPlay, size: 24.r),
                label: Text('Play', style: TextStyle(fontSize: 16.sp)),
                onPressed: () async {
                  final service = ref.read(quranAudioPlayerProvider);
                  final from = ref.read(selectedStartAyahProvider);
                  final to = ref.read(selectedEndAyahProvider);
                  final bool playbackStarted = await service.playAyahs(from, to, context);
                  if (!context.mounted) return;
                  if (playbackStarted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            SizedBox(height: 44.h),
          ],
        ),
      ),
    );
  }

  // --- The _labeledDropdown helper method is unchanged ---
  Widget _labeledDropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 20.r),
        SizedBox(width: 8.w),
        Text(
          "$label:",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF294B39),
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isExpanded: true,
                value: value,
                dropdownColor: const Color(0xFF294B39),
                iconEnabledColor: Colors.white,
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
                items: items.map((e) {
                  return DropdownMenuItem<T>(
                    value: e,
                    child: Text(
                      e.toString(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: 16.sp),
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