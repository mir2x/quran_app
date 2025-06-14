import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodel/ayah_highlight_viewmodel.dart';


class AudioControllerBar extends ConsumerWidget {
  final Color color;
  const AudioControllerBar({super.key, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quranState = ref.watch(quranAudioProvider);
    if (quranState == null) return const SizedBox.shrink();

    final service = ref.read(audioPlayerServiceProvider);
    final surah = quranState.surah;
    final ayah = quranState.ayah;
    final isPlaying = quranState.isPlaying;

    return Material(
      elevation: 6,
      color: color,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Text('$surah : $ayah',
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                  tooltip: 'Previous Ayah',
                  onPressed: service.playPrev,
                ),
                IconButton(
                  icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white),
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  onPressed: service.togglePlayPause,
                ),
                IconButton(
                  icon: const Icon(Icons.stop, color: Colors.white),
                  tooltip: 'Stop',
                  onPressed: service.stop,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                  tooltip: 'Next Ayah',
                  onPressed: service.playNext,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
