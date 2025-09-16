import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/sura/model/ayah.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/utils/database_helper.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  return DatabaseHelper().database;
});

final quranDataServiceProvider = Provider<QuranDataService>((ref) {
  return QuranDataService();
});

class QuranDataService {
  Future<int> getVerseCount(Database db, int suraNumber) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ayahs WHERE sura = ?',
      [suraNumber],
    );
    return result.isNotEmpty ? Sqflite.firstIntValue(result) ?? 0 : 0;
  }

  Future<Ayah> getAyah(Database db, int suraNumber, int ayahNumber) async {
    final ayahMap = await db.query(
      'ayahs',
      where: 'sura = ? AND ayah = ?',
      whereArgs: [suraNumber, ayahNumber],
    );

    if (ayahMap.isEmpty) {
      throw Exception('Ayah not found: $suraNumber:$ayahNumber');
    }

    final translationsMap = await db.query(
      'translations',
      where: 'sura = ? AND ayah = ?',
      whereArgs: [suraNumber, ayahNumber],
    );
    final translations = translationsMap
        .map((row) => Translation.fromDb(row))
        .toList();

    final wordsMap = await db.query(
      'words',
      where: 'sura = ? AND ayah = ?',
      whereArgs: [suraNumber, ayahNumber],
      orderBy: 'word_id ASC',
    );
    final words = wordsMap.map((row) => WordByWord.fromDb(row)).toList();

    return Ayah.fromDb(ayahMap.first, translations: translations, words: words);
  }

  Future<List<Ayah>> searchQuran(Database db, String query) async {
    final String searchTerm = '%$query%';

    // Step 1: Get the unique IDs of all matching Ayahs. This is fast and unchanged.
    final List<Map<String, dynamic>> idResults = await db.rawQuery('''
    SELECT DISTINCT sura, ayah FROM ayahs WHERE arabic_text LIKE ?
    UNION
    SELECT DISTINCT sura, ayah FROM translations WHERE translation_text LIKE ?
    ORDER BY sura, ayah
  ''', [searchTerm, searchTerm]);

    if (idResults.isEmpty) {
      return [];
    }

    // --- THE FIX: BATCHING THE QUERIES ---
    const int chunkSize = 250; // A safe number, well below the SQLite limit of 999
    final List<Ayah> resultAyahs = [];

    // Loop through the IDs in chunks of 250
    for (int i = 0; i < idResults.length; i += chunkSize) {
      // Get the sublist for the current chunk
      final chunkIds = idResults.sublist(
          i, i + chunkSize > idResults.length ? idResults.length : i + chunkSize);

      if (chunkIds.isEmpty) continue;

      // Step 2: Prepare a WHERE clause for this chunk only.
      final whereClause = chunkIds.map((_) => '(sura = ? AND ayah = ?)').join(' OR ');
      final whereArgs = chunkIds.expand((row) => [row['sura'], row['ayah']]).toList();

      // Step 3: Fetch all data for this chunk in parallel.
      final ayahsFuture = db.query('ayahs', where: whereClause, whereArgs: whereArgs);
      final translationsFuture = db.query('translations', where: whereClause, whereArgs: whereArgs);
      final wordsFuture = db.query('words', where: whereClause, whereArgs: whereArgs, orderBy: 'word_id ASC');

      final allData = await Future.wait([
        ayahsFuture,
        translationsFuture,
        wordsFuture,
      ]);

      final List<Map<String, dynamic>> ayahData = allData[0];
      final List<Map<String, dynamic>> translationData = allData[1];
      final List<Map<String, dynamic>> wordData = allData[2];

      // Step 4: Stitch the data for this chunk together (same logic as before).
      final Map<String, List<Translation>> translationsByAyah = {};
      for (final row in translationData) {
        final key = "${row['sura']}:${row['ayah']}";
        translationsByAyah.putIfAbsent(key, () => []).add(Translation.fromDb(row));
      }

      final Map<String, List<WordByWord>> wordsByAyah = {};
      for (final row in wordData) {
        final key = "${row['sura']}:${row['ayah']}";
        wordsByAyah.putIfAbsent(key, () => []).add(WordByWord.fromDb(row));
      }

      // Add the processed ayahs from this chunk to our main results list.
      for (final row in ayahData) {
        final key = "${row['sura']}:${row['ayah']}";
        resultAyahs.add(Ayah.fromDb(
          row,
          translations: translationsByAyah[key] ?? [],
          words: wordsByAyah[key] ?? [],
        ));
      }
    }

    // Ensure the final list is sorted correctly, as chunks might process out of order.
    resultAyahs.sort((a, b) {
      if (a.sura != b.sura) return a.sura.compareTo(b.sura);
      return a.ayah.compareTo(b.ayah);
    });

    return resultAyahs;
  }
}

final ayahCountProvider = FutureProvider.family<int, int>((
  ref,
  suraNumber,
) async {
  final db = await ref.watch(databaseProvider.future);
  return ref.read(quranDataServiceProvider).getVerseCount(db, suraNumber);
});

class AyahProviderParams {
  final int suraNumber;
  final int index; // 0-based index from ListView.builder

  AyahProviderParams({required this.suraNumber, required this.index});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AyahProviderParams &&
          runtimeType == other.runtimeType &&
          suraNumber == other.suraNumber &&
          index == other.index;

  @override
  int get hashCode => suraNumber.hashCode ^ index.hashCode;
}

final ayahByIndexProvider = FutureProvider.family<Ayah, AyahProviderParams>((
  ref,
  params,
) async {
  final db = await ref.watch(databaseProvider.future);
  final ayahNumber = params.index + 1;
  return ref
      .read(quranDataServiceProvider)
      .getAyah(db, params.suraNumber, ayahNumber);
});

final selectedTranslatorsProvider = StateProvider<List<String>>(
  (ref) => ['মুফতী তাকী উসমানী'],
);
final showTranslationsProvider = StateProvider<bool>((ref) => true);
final showWordByWordProvider = StateProvider<bool>((ref) => false);
final isAutoScrollingProvider = StateProvider<bool>((ref) => false);
final scrollSpeedFactorProvider = StateProvider<double>((ref) => 1.0);
final isAutoScrollPausedProvider = StateProvider<bool>((ref) => false);
