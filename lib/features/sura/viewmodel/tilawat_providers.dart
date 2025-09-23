import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/tilawat_models.dart';

// Use .family to accept the sura number and filter the results.
final quranPagesProvider = FutureProvider.family<List<QuranPage>, int>((ref, int suraNumber) async {
  final jsonString = await rootBundle.loadString('assets/sura_data.json');
  final Map<String, dynamic> jsonData = json.decode(jsonString);
  final List<dynamic> surasJson = jsonData['suras'];

  // --- NEW, EFFICIENT LOGIC ---

  // 1. Find the specific Surah JSON object from the list.
  final targetSuraJson = surasJson.firstWhere(
        (sura) => sura['sura_number'] == suraNumber,
    orElse: () => null, // Return null if not found
  );

  // If the surah wasn't found, return an empty list to prevent errors.
  if (targetSuraJson == null) {
    return [];
  }

  final List<QuranPage> surahPages = [];
  int localPageCounter = 0; // This counter is specific to this Surah.

  final String suraNameBengali = targetSuraJson['name_bengali'];
  final String suraNameArabic = targetSuraJson['name_arabic'];
  final int paraNumber = targetSuraJson['para_number'];

  // 2. Loop ONLY through the pages of the found Surah.
  for (var pageJson in targetSuraJson['pages']) {
    localPageCounter++; // Increment the local page count (1, 2, 3...)

    final List<dynamic> ayahsJson = pageJson['ayahs'];
    final List<TilawatAyah> ayahs =
    ayahsJson.map((ayahJson) => TilawatAyah.fromJson(ayahJson)).toList();

    // 3. Create a QuranPage object using the LOCAL page number.
    surahPages.add(
      QuranPage(
        pageNumberInSurah: localPageCounter, // Use the local counter here
        paraNumber: paraNumber,
        content: [
          PageContent(
            suraNumber: suraNumber,
            suraNameBengali: suraNameBengali,
            suraNameArabic: suraNameArabic,
            ayahs: ayahs,
          )
        ],
      ),
    );
  }

  return surahPages;
});