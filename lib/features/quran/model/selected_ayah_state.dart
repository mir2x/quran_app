enum AyahSelectionSource {
  tap,
  audio,
  navigation,
}

class SelectedAyahState {
  final int suraNumber;
  final int ayahNumber;
  final AyahSelectionSource source;

  const SelectedAyahState(this.suraNumber, this.ayahNumber, this.source);

  SelectedAyahState copyWith({
    int? suraNumber,
    int? ayahNumber,
    AyahSelectionSource? source,
  }) {
    return SelectedAyahState(
      suraNumber ?? this.suraNumber,
      ayahNumber ?? this.ayahNumber,
      source ?? this.source,
    );
  }
}