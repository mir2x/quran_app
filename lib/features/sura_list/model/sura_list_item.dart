enum RevelationType {
  Makki,
  Madani,
}

class SuraListItemModel {
  final int number;
  final String nameBangla;
  final String meaningBangla;
  final RevelationType revelationType;
  final String nameArabic;

  const SuraListItemModel({
    required this.number,
    required this.nameBangla,
    required this.meaningBangla,
    required this.revelationType,
    required this.nameArabic,
  });
}