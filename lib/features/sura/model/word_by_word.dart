class WordByWord {
  final int sura;
  final int ayah;
  final String arabic;
  final String bengali;

  WordByWord({
    required this.sura,
    required this.ayah,
    required this.arabic,
    required this.bengali,
  });

  factory WordByWord.fromJson(Map<String, dynamic> json) {
    return WordByWord(
      sura: json['sura'],
      ayah: json['ayah'],
      arabic: json['Arabic'],
      bengali: json['bn'],
    );
  }
}