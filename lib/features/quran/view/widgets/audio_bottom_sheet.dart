import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/services/fileChecker.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart';
import '../../../../shared/downloader/download_dialog.dart';
import '../../../../shared/downloader/download_permission_dialog.dart';

class AudioBottomSheet extends ConsumerStatefulWidget {
  final int currentSura;

  const AudioBottomSheet({super.key, required this.currentSura});

  @override
  ConsumerState<AudioBottomSheet> createState() => _AudioBottomSheetState();
}

class _AudioBottomSheetState extends ConsumerState<AudioBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final selectedReciter = ref.watch(selectedReciterProvider);
    final startAyah = ref.watch(selectedStartAyahProvider);
    final endAyah = ref.watch(selectedEndAyahProvider);
    final ayahCounts = ref.watch(ayahCountsProvider);
    final lastAyah = ayahCounts[widget.currentSura - 1];
    final ayahOptions = List.generate(lastAyah, (i) => i + 1);

    return Container(
      color: const Color(0xFF294B39),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            items: ayahOptions,
            onChanged: (val) {
              if (val != null) {
                ref.read(selectedStartAyahProvider.notifier).state = val;
                if (val > endAyah) {
                  ref.read(selectedEndAyahProvider.notifier).state = val;
                }
              }
            },
          ),
          const SizedBox(height: 12),
          _labeledDropdown<int>(
            label: "শেষ আয়াত",
            icon: HugeIcons.solidRoundedSquareArrowRight03,
            value: endAyah,
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
                final downloaded = await isDownloaded(reciterId);

                if (!downloaded) {
                  final reciter = ref.read(reciterCatalogueProvider)
                      .firstWhere((r) => r.id == reciterId);

                  final confirmed =
                  await downloadPermissionDialog(context, reciter.name);

                  if (!confirmed) return;

                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => DownloadDialog(reciter: reciter),
                  );
                }

                // Step 3: Load timing after download
                await ref.read(audioVMProvider.notifier).loadTimings();

                // Step 4: Proceed with playback
                final from = ref.read(selectedStartAyahProvider);
                final to = ref.read(selectedEndAyahProvider);
                final service = ref.read(audioPlayerServiceProvider);
                service.setCurrentSura(widget.currentSura);
                await service.playAyahs(from, to);
                if (context.mounted) Navigator.pop(context);
              },

            ),
          ),
        ],
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
                  return DropdownMenuItem<T>(
                    value: e,
                    child: Text(
                      e.toString(),
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
