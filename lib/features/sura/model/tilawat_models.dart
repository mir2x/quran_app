class TilawatAyah {
  final int ayahNumber;
  final String text;

  TilawatAyah({required this.ayahNumber, required this.text});

  factory TilawatAyah.fromJson(Map<String, dynamic> json) {
    return TilawatAyah(
      ayahNumber: json['ayah_number_in_sura'] as int,
      text: json['text'] as String? ?? '',
    );
  }
}

class PageContent {
  final int suraNumber;
  final String suraNameBengali;
  final String suraNameArabic;
  final List<TilawatAyah> ayahs;

  PageContent({
    required this.suraNumber,
    required this.suraNameBengali,
    required this.suraNameArabic,
    required this.ayahs,
  });
}

class QuranPage {
  // FIX: Renamed for clarity. This now represents the page number within its own Surah.
  final int pageNumberInSurah;
  final int paraNumber;
  final List<PageContent> content;

  QuranPage({
    required this.pageNumberInSurah,
    required this.paraNumber,
    required this.content,
  });
}