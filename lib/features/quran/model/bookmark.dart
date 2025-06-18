class Bookmark {
  final String type;
  final String identifier;
  final DateTime timestamp;

  final int? sura;
  final int? para;
  final int? page;
  final int? ayah;

  Bookmark({
    required this.type,
    required this.identifier,
    DateTime? timestamp,
    this.sura,
    this.para,
    this.page,
    this.ayah,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'identifier': identifier,
      'timestamp': timestamp.toIso8601String(),
      'sura': sura,
      'para': para,
      'page': page,
      'ayah': ayah,
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      type: json['type'],
      identifier: json['identifier'],
      timestamp: DateTime.parse(json['timestamp'] as String),
      sura: json['sura'] as int?,
      para: json['para'] as int?,
      page: json['page'] as int?,
      ayah: json['ayah'] as int?,
    );
  }
}