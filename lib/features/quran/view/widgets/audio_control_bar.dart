import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../viewmodel/audio_providers.dart';
import 'package:quran_app/features/sura/view/widgets/reciter_selection_dialog.dart';

class AudioControllerBar extends ConsumerWidget {
  final Color color;
  const AudioControllerBar({super.key, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quranState = ref.watch(quranAudioProvider);
    if (quranState == null) return const SizedBox.shrink();

    final service = ref.read(quranAudioPlayerProvider);
    final surah = quranState.surah;
    final ayah = quranState.ayah;
    final isPlaying = quranState.isPlaying;

    return Material(
      elevation: 6,
      color: color,
      child: Container(
        // Scale height using .h
        height: 60.h,
        // Scale padding using .w
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Row(
          children: [
            Expanded(
              child: Text(
                // No change to text content
                '$surah : $ayah',
                style: TextStyle(
                  // Remove const as font size is scaled
                  color: Colors.white,
                  // Scale font size using .sp
                  fontSize: 16.sp,
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.skip_previous,
                    color: Colors.white,
                    // Scale icon size using .r (Optional)
                    size: 24.r, // Example scaling
                  ),
                  tooltip: 'Previous Ayah', // Tooltip text remains
                  onPressed: service.playPrev,
                ),
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    // Scale icon size using .r (Optional)
                    size: 24.r, // Example scaling
                  ),
                  tooltip: isPlaying ? 'Pause' : 'Play', // Tooltip text remains
                  onPressed: service.togglePlayPause,
                ),
                IconButton(
                  icon: Icon(
                    Icons.stop,
                    color: Colors.white,
                    // Scale icon size using .r (Optional)
                    size: 24.r, // Example scaling
                  ),
                  tooltip: 'Stop', // Tooltip text remains
                  onPressed: service.stop,
                ),
                IconButton(
                  icon: Icon(
                    Icons.skip_next,
                    color: Colors.white,
                    // Scale icon size using .r (Optional)
                    size: 24.r, // Example scaling
                  ),
                  tooltip: 'Next Ayah', // Tooltip text remains
                  onPressed: service.playNext,
                ),
                IconButton(
                  icon: Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 24.r,
                  ),
                  tooltip: 'Change Qari',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const ReciterSelectionDialog(),
                    );
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
