import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart';

class AudioBottomSheet extends ConsumerStatefulWidget {
  final int currentSura;
  const AudioBottomSheet({super.key, required this.currentSura});

  @override
  ConsumerState<AudioBottomSheet> createState() => _AudioBottomSheetState();
}

class _AudioBottomSheetState extends ConsumerState<AudioBottomSheet> {
  bool _loadingTriggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadingTriggered) {
      _loadingTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(audioVMProvider.notifier).loadWithContext(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioVM = ref.watch(audioVMProvider);
    final startAyah = ref.watch(selectedStartAyahProvider);
    final endAyah = ref.watch(selectedEndAyahProvider);

    return audioVM.when(
      data: (_) {
        final vm = ref.read(audioVMProvider.notifier);
        final selectedReciter = ref.watch(selectedReciterProvider);
        final lastAyah = vm.getLastAyah(widget.currentSura);
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF294B39),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () async {
                    final from = ref.read(selectedStartAyahProvider);
                    final to = ref.read(selectedEndAyahProvider);
                    final service = ref.read(audioPlayerServiceProvider);
                    service.setCurrentSura(widget.currentSura);
                    await service.playAyahs(from, to);
                    Navigator.pop(context);
                  },
                ),
              )
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text("Error: $e", style: TextStyle(color: Colors.red))),
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

