import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/tilawat_models.dart';

// Use .family to accept the sura number and filter the results.
final quranPagesProvider = FutureProvider.family<List<QuranPage>, int>((ref, int suraNumber) async {
  final jsonString = await rootBundle.loadString('assets/sura_data.json');
  final Map<String, dynamic> jsonData = json.decode(jsonString);
  final List<dynamic> surasJson = jsonData['suras'];

  final List<QuranPage> allPages = [];
  int globalPageCounter = 0;

  // First, parse all pages in the entire Quran to handle pages that might contain multiple surahs.
  for (var suraJson in surasJson) {
    for (var pageJson in suraJson['pages']) {
      globalPageCounter++;
      final List<dynamic> ayahsJson = pageJson['ayahs'];
      final List<TilawatAyah> ayahs =
      ayahsJson.map((ayahJson) => TilawatAyah.fromJson(ayahJson)).toList();

      final newContent = PageContent(
        suraNumber: suraJson['sura_number'],
        suraNameBengali: suraJson['name_bengali'],
        suraNameArabic: suraJson['name_arabic'],
        ayahs: ayahs,
      );

      int existingPageIndex = allPages.indexWhere((p) => p.globalPageNumber == globalPageCounter);
      if (existingPageIndex != -1) {
        allPages[existingPageIndex].content.add(newContent);
      } else {
        allPages.add(
          QuranPage(
            globalPageNumber: globalPageCounter,
            paraNumber: suraJson['para_number'],
            content: [newContent],
          ),
        );
      }
    }
  }

  // **THE CRITICAL STEP**: Filter the fully parsed list to get only the pages
  // that contain any content from the requested surah.
  final filteredPages = allPages
      .where((page) => page.content.any((content) => content.suraNumber == suraNumber))
      .toList();

  return filteredPages;
});