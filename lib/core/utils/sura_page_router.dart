import 'package:flutter/material.dart';
import '../../features/sura/view/sura_page.dart';

MaterialPageRoute<dynamic> createSurahPageRoute(int suraNumber, int? initialScrollIndex) {
  return MaterialPageRoute(
    // Give the route a unique name based on the sura number
    settings: RouteSettings(name: '/surah/$suraNumber'),
    builder: (context) => SurahPage(
      suraNumber: suraNumber,
      initialScrollIndex: initialScrollIndex,
    ),
  );
}