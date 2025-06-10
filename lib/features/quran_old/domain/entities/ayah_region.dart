import 'dart:convert';

import 'ayah_box.dart';

class AyahRegion {
  final String sura;
  final String ayah;
  final List<AyahBox> boxes;

  AyahRegion({
    required this.sura,
    required this.ayah,
    required this.boxes,
  });

  String get key => '${sura.padLeft(3, '0')}:${ayah.padLeft(3, '0')}';
}

Future<List<AyahRegion>> parseGroupedRegions(String jsonStr) async {
  final decoded = jsonDecode(jsonStr);
  final metadata = decoded['_via_img_metadata'] as Map<String, dynamic>;
  final imageKey = metadata.keys.first;
  final regions = metadata[imageKey]['regions'] as List;

  final Map<String, List<AyahBox>> grouped = {};

  for (var r in regions) {
    final attributes = r['region_attributes'] as Map<String, dynamic>;
    final sura = attributes['sura']?.toString() ?? 'unknown';
    final ayah = attributes['ayah']?.toString() ?? 'unknown';
    final key = '$sura:$ayah';

    final shape = AyahBox.fromJson(r['shape_attributes']);
    grouped.putIfAbsent(key, () => []).add(shape);
  }

  return grouped.entries.map((entry) {
    final parts = entry.key.split(':');
    return AyahRegion(
      sura: parts[0],
      ayah: parts[1],
      boxes: entry.value,
    );
  }).toList();
}
