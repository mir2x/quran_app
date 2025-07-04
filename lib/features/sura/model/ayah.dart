import 'package:quran_app/features/sura/model/word_by_word.dart';

class Ayah {
  final int sura;
  final int ayah;
  final String arabicText;
  final List<Translation> translations;
  final List<WordByWord> words;

  Ayah({
    required this.sura,
    required this.ayah,
    required this.arabicText,
    required this.translations,
    required this.words,
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