class AyahTiming {
  final int ayah;
  final int sura;
  final int time;

  AyahTiming({
    required this.ayah,
    required this.sura,
    required this.time,
  });

  factory AyahTiming.fromJson(Map<String, dynamic> json) {
    return AyahTiming(
      ayah: json['ayah'],
      sura: json['sura'],
      time: json['time'],
    );
  }
}
