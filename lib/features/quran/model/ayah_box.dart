class AyahBox {
  final int ayahNumber;
  final int boxId;
  final double minX, minY, maxX, maxY;
  final int pageNumber;
  final int suraNumber;

  const AyahBox({
    required this.ayahNumber,
    required this.boxId,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
    required this.pageNumber,
    required this.suraNumber,
  });

  factory AyahBox.fromJson(Map<String, dynamic> j) => AyahBox(
    ayahNumber: j['ayah_number'],
    boxId:      j['box_id'],
    minX:       (j['min_x'] as num).toDouble(),
    minY:       (j['min_y'] as num).toDouble(),
    maxX:       (j['max_x'] as num).toDouble(),
    maxY:       (j['max_y'] as num).toDouble(),
    pageNumber: j['page_number'],
    suraNumber: j['sura_number'],
  );

  double get width  => maxX - minX;
  double get height => maxY - minY;

  bool contains(double x, double y) =>
      x >= minX && x <= maxX && y >= minY && y <= maxY;
}
