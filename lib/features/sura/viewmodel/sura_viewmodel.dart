import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/sura/model/ayah.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/utils/database_helper.dart';

// --- NO CHANGES TO THESE TOP PROVIDERS ---
final databaseProvider = FutureProvider<Database>((ref) async {
  return DatabaseHelper().database;
});

final quranDataServiceProvider = Provider<QuranDataService>((ref) {
  return QuranDataService();
});


class QuranDataService {
  // --- NEW METHOD TO FETCH ALL AYAH DATA FOR A SURAH ---
  Future<List<Ayah>> getAyahsForSura(Database db, int suraNumber) async {
    // 1. Fetch all data for the given surah in parallel
    final allDataFuture = Future.wait([
      db.query('ayahs', where: 'sura = ?', whereArgs: [suraNumber]),
      db.query('translations', where: 'sura = ?', whereArgs: [suraNumber]),
      db.query('words', where: 'sura = ?', whereArgs: [suraNumber], orderBy: 'word_id ASC'),
    ]);

    final allData = await allDataFuture;
    final List<Map<String, dynamic>> ayahData = allData[0];
    final List<Map<String, dynamic>> translationData = allData[1];
    final List<Map<String, dynamic>> wordData = allData[2];

    if (ayahData.isEmpty) {
      return []; // Return an empty list if the surah has no ayahs
    }

    // 2. Process translations and words into maps for efficient lookup
    final Map<int, List<Translation>> translationsByAyah = {};
    for (final row in translationData) {
      final ayahNum = row['ayah'] as int;
      translationsByAyah.putIfAbsent(ayahNum, () => []).add(Translation.fromDb(row));
    }

    final Map<int, List<WordByWord>> wordsByAyah = {};
    for (final row in wordData) {
      final ayahNum = row['ayah'] as int;
      wordsByAyah.putIfAbsent(ayahNum, () => []).add(WordByWord.fromDb(row));
    }

    // 3. Stitch everything together into a list of Ayah objects
    final List<Ayah> resultAyahs = [];
    for (final row in ayahData) {
      final ayahNum = row['ayah'] as int;
      resultAyahs.add(Ayah.fromDb(
        row,
        translations: translationsByAyah[ayahNum] ?? [],
        words: wordsByAyah[ayahNum] ?? [],
      ));
    }

    return resultAyahs;
  }
  // --- END OF NEW METHOD ---


  Future<int> getVerseCount(Database db, int suraNumber) async {
    // ... existing method is unchanged
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ayahs WHERE sura = ?',
      [suraNumber],
    );
    return result.isNotEmpty ? Sqflite.firstIntValue(result) ?? 0 : 0;
  }

  Future<Ayah> getAyah(Database db, int suraNumber, int ayahNumber) async {
    // ... existing method is unchanged
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
    // ... existing method is unchanged
    final String searchTerm = '%$query%';
    final List<Map<String, dynamic>> idResults = await db.rawQuery('''
    SELECT DISTINCT sura, ayah FROM ayahs WHERE arabic_text LIKE ?
    UNION
    SELECT DISTINCT sura, ayah FROM translations WHERE translation_text LIKE ?
    ORDER BY sura, ayah
  ''', [searchTerm, searchTerm]);
    if (idResults.isEmpty) {
      return [];
    }
    const int chunkSize = 250;
    final List<Ayah> resultAyahs = [];
    for (int i = 0; i < idResults.length; i += chunkSize) {
      final chunkIds = idResults.sublist(
          i, i + chunkSize > idResults.length ? idResults.length : i + chunkSize);
      if (chunkIds.isEmpty) continue;
      final whereClause = chunkIds.map((_) => '(sura = ? AND ayah = ?)').join(' OR ');
      final whereArgs = chunkIds.expand((row) => [row['sura'], row['ayah']]).toList();
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
      for (final row in ayahData) {
        final key = "${row['sura']}:${row['ayah']}";
        resultAyahs.add(Ayah.fromDb(
          row,
          translations: translationsByAyah[key] ?? [],
          words: wordsByAyah[key] ?? [],
        ));
      }
    }
    resultAyahs.sort((a, b) {
      if (a.sura != b.sura) return a.sura.compareTo(b.sura);
      return a.ayah.compareTo(b.ayah);
    });
    return resultAyahs;
  }
}

// --- NEW PROVIDER FOR THE REFACTORED SURAH PAGE ---
final suraDataProvider = FutureProvider.family<List<Ayah>, int>((
    ref,
    suraNumber,
    ) async {
  final db = await ref.watch(databaseProvider.future);
  return ref.read(quranDataServiceProvider).getAyahsForSura(db, suraNumber);
});
// --- END OF NEW PROVIDER ---


// --- OLD PROVIDERS (can be kept for other parts of the app, but not used by the new SurahPage) ---
final ayahCountProvider = FutureProvider.family<int, int>((
    ref,
    suraNumber,
    ) async {
  // ... implementation unchanged
  final db = await ref.watch(databaseProvider.future);
  return ref.read(quranDataServiceProvider).getVerseCount(db, suraNumber);
});

class AyahProviderParams {
  // ... implementation unchanged
  final int suraNumber;
  final int index;
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
  // ... implementation unchanged
  final db = await ref.watch(databaseProvider.future);
  final ayahNumber = params.index + 1;
  return ref
      .read(quranDataServiceProvider)
      .getAyah(db, params.suraNumber, ayahNumber);
});

// --- UI STATE PROVIDERS (unchanged) ---
final selectedTranslatorsProvider = StateProvider<List<String>>(
      (ref) => [],
);

class ScrollCommand {
  final int suraNumber;
  final int scrollIndex;

  ScrollCommand({required this.suraNumber, required this.scrollIndex});
}
final activeSurahPagesProvider = StateProvider<Set<int>>((ref) => {});
final suraScrollCommandProvider = StateProvider<ScrollCommand?>((ref) => null);
final showTranslationsProvider = StateProvider<bool>((ref) => true);
final showWordByWordProvider = StateProvider<bool>((ref) => false);
final isAutoScrollingProvider = StateProvider<bool>((ref) => false);
final scrollSpeedFactorProvider = StateProvider<double>((ref) => 1.0);
final isAutoScrollPausedProvider = StateProvider<bool>((ref) => false);