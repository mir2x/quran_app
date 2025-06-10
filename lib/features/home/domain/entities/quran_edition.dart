class QuranEdition {
  final String coverImagePath;
  final String title;
  final String assetPath;
  final int imageWidth;
  final int imageHeight;
  final List<String> imageFiles;
  final List<String> jsonFiles;
  final bool hasCheckmark;

  const QuranEdition({required this.coverImagePath, required this.title, required this.assetPath, required this.imageWidth, required this.imageHeight, required this.imageFiles, required this.jsonFiles, this.hasCheckmark = false});
}