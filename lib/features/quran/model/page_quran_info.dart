class PageQuranInfo {
  final int pageNumber;
  final int? paraNumber;
  final Map<int, (int, int)> suraAyahRanges;

  PageQuranInfo({
    required this.pageNumber,
    this.paraNumber,
    required this.suraAyahRanges,
  });

  List<int> get surasOnPage => suraAyahRanges.keys.toList()..sort();
}