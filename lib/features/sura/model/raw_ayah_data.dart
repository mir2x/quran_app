class RawAyahData {
  final int sura;
  final int ayah;
  final String text;

  RawAyahData({
    required this.sura,
    required this.ayah,
    required this.text,
  });

  factory RawAyahData.fromJson(Map<String, dynamic> json) {
    return RawAyahData(
      sura: int.parse(json['sura']),
      ayah: int.parse(json['ayah']),
      text: json['text'],
    );
  }
}