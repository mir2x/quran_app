class Ayah {
  final int sura;
  final int ayah;
  final String arabicText;
  final List<Translation> translations;

  Ayah({
    required this.sura,
    required this.ayah,
    required this.arabicText,
    required this.translations,
  });
}

class Translation {
  final String translatorName;
  final String text;

  Translation({
    required this.translatorName,
    required this.text,
  });
}