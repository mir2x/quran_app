// In your model/bookmark.dart file (or wherever Bookmark is defined)

class Bookmark {
  final String type; // 'ayah' or 'page'
  final String identifier; // Keep for uniqueness, maybe update format
  final DateTime timestamp;

  final int? sura;  // Make nullable
  final int? para;  // Make nullable
  final int? page;  // Make nullable
  final int? ayah; // Make nullable explicitly

  Bookmark({
    required this.type,
    required this.identifier,
    DateTime? timestamp,
    this.sura, // Make optional in constructor
    this.para,  // Make optional in constructor
    this.page,  // Make optional in constructor
    this.ayah, // Make optional in constructor
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
    // Safely read potentially missing or null fields using `as int?`
    // Provide a default value like -1 or 0 if null, as the UI/navigation might expect int.
    // Using -1 makes it clear it's invalid data.
    return Bookmark(
      type: json['type'],
      identifier: json['identifier'],
      timestamp: DateTime.parse(json['timestamp'] as String), // Explicit cast to String for safety
      sura: json['sura'] as int?,
      para: json['para'] as int?,
      page: json['page'] as int?,
      ayah: json['ayah'] as int?,
    );
  }
}