class QuranAudioState {
  final int surah;
  final int ayah;
  final bool isPlaying;

  QuranAudioState({required this.surah, required this.ayah, required this.isPlaying});

  QuranAudioState copyWith({int? surah, int? ayah, bool? isPlaying}) {
    return QuranAudioState(
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}
