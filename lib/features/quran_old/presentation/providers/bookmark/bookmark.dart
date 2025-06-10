class Bookmark {
  final String type;
  final String identifier;
  final DateTime timestamp;

  Bookmark({
    required this.type,
    required this.identifier,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'identifier': identifier,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      type: json['type'],
      identifier: json['identifier'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
