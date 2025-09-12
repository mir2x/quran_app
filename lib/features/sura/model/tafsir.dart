class TafsirSource {
  final String id;
  final String title;
  final String url;
  final int sizeBytes;

  final bool isDownloaded;
  final String? content;

  TafsirSource({
    required this.id,
    required this.title,
    required this.url,
    required this.sizeBytes,
    this.isDownloaded = false,
    this.content,
  });
}