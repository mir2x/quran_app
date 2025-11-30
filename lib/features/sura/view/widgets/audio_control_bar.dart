import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../viewmodel/sura_reciter_viewmodel.dart';

class AudioControllerBar extends ConsumerWidget {
  final Color color;
  const AudioControllerBar({super.key, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quranState = ref.watch(suraAudioProvider);
    if (quranState == null) return const SizedBox.shrink();

    final service = ref.read(suraAudioPlayerProvider);
    final surah = quranState.surah;
    final ayah = quranState.ayah;
    final isPlaying = quranState.isPlaying;

    return Material(
      elevation: 6,
      color: color,
      child: Container(
        height: 60.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Row(
          children: [
            Expanded(
              child: Text('$surah : $ayah',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                  )),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.skip_previous,
                    color: Colors.white,
                    size: 24.r,
                  ),
                  tooltip: 'Previous Ayah',
                  onPressed: service.playPrev,
                ),
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 24.r,
                  ),
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  onPressed: service.togglePlayPause,
                ),
                IconButton(
                  icon: Icon(
                    Icons.stop,
                    color: Colors.white,
                    size: 24.r,
                  ),
                  tooltip: 'Stop',
                  onPressed: service.stop,
                ),
                IconButton(
                  icon: Icon(
                    Icons.skip_next,
                    color: Colors.white,
                    size: 24.r,
                  ),
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
