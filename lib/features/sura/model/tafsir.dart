class TafsirSource {
  final String title;
  final String sourceId;
  final String content;

  TafsirSource({
    required this.title,
    required this.sourceId,
    this.content = "তাফসীর পাওয়া যায়নি।",
  });
}