import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart';


class AudioBottomSheet extends ConsumerWidget {
  final int currentSura;

  const AudioBottomSheet({super.key, required this.currentSura});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioVM = ref.watch(audioVMProvider);
    final selectedReciter = ref.watch(selectedReciterProvider);
    final startAyah = ref.watch(selectedStartAyahProvider);
    final endAyah = ref.watch(selectedEndAyahProvider);

    return audioVM.when(
      data: (_) {
        final vm = ref.read(audioVMProvider.notifier);
        final lastAyah = vm.getLastAyah(currentSura);
        final ayahOptions = List.generate(lastAyah, (i) => i + 1);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text("Reciter:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: selectedReciter,
                    items: reciters
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(selectedReciterProvider.notifier).state = val;
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Text("Start Ayah:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: startAyah,
                    items: ayahOptions
                        .map((a) => DropdownMenuItem(value: a, child: Text(a.toString())))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(selectedStartAyahProvider.notifier).state = val;
                        if (val > endAyah) {
                          ref.read(selectedEndAyahProvider.notifier).state = val;
                        }
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Text("End Ayah:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: endAyah,
                    items: ayahOptions
                        .where((a) => a >= startAyah)
                        .map((a) => DropdownMenuItem(value: a, child: Text(a.toString())))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(selectedEndAyahProvider.notifier).state = val;
                      }
                    },
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                  onPressed: () async {
                    final sura = currentSura;
                    final from = ref.read(selectedStartAyahProvider);
                    final to = ref.read(selectedEndAyahProvider);

                    final service = ref.read(audioPlayerServiceProvider);
                    service.setCurrentSura(sura);
                    await service.playAyahs(from, to);
                    Navigator.pop(context);
                  }
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }
}
