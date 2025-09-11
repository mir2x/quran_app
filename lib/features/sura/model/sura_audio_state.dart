class SuraAudioState {
  final int surah;
  final int ayah;
  final bool isPlaying;

  SuraAudioState({required this.surah, required this.ayah, required this.isPlaying});

  SuraAudioState copyWith({int? surah, int? ayah, bool? isPlaying}) {
    return SuraAudioState(
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}
