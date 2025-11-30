import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/tilawat_models.dart';

final quranPagesProvider =
    FutureProvider.family<List<QuranPage>, int>((ref, int suraNumber) async {
  final jsonString = await rootBundle.loadString('assets/sura_data.json');
  final Map<String, dynamic> jsonData = json.decode(jsonString);
  final List<dynamic> surasJson = jsonData['suras'];

  final targetSuraJson = surasJson.firstWhere(
    (sura) => sura['sura_number'] == suraNumber,
    orElse: () => null,
  );

  if (targetSuraJson == null) {
    return [];
  }

  final List<QuranPage> surahPages = [];
  int localPageCounter = 0;

  final String suraNameBengali = targetSuraJson['name_bengali'];
  final String suraNameArabic = targetSuraJson['name_arabic'];
  final int paraNumber = targetSuraJson['para_number'];

  for (var pageJson in targetSuraJson['pages']) {
    localPageCounter++;

    final List<dynamic> ayahsJson = pageJson['ayahs'];
    final List<TilawatAyah> ayahs =
        ayahsJson.map((ayahJson) => TilawatAyah.fromJson(ayahJson)).toList();

    surahPages.add(
      QuranPage(
        pageNumberInSurah: localPageCounter,
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
