import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AyahAudioRange {
  final String sura;
  final String ayah;
  final Duration start;
  final Duration end;

  AyahAudioRange({
    required this.sura,
    required this.ayah,
    required this.start,
    required this.end,
  });

  String get key =>
      '${sura.padLeft(3, '0')}:${int.parse(ayah).toString().padLeft(3, '0')}';

  factory AyahAudioRange.fromJson(Map<String, dynamic> json) {
    return AyahAudioRange(
      sura: json['sura'].toString(),
      ayah: json['ayah'].toString(),
      start: Duration(milliseconds: (json['start'] * 1000).toInt()),
      end: Duration(milliseconds: (json['end'] * 1000).toInt()),
    );
  }

  static Future<List<AyahAudioRange>> loadFromAsset(String assetPath) async {
    final jsonStr = await rootBundle.loadString(assetPath);
    final List decoded = jsonDecode(jsonStr) as List;
    return decoded
        .map((j) => AyahAudioRange.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
