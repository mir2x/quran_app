import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// --- Models to parse the JSON easily ---
class RawAyahData {
  final int sura, ayah;
  final String text;
  RawAyahData(this.sura, this.ayah, this.text);

  // FIX 1: Parse the string values from JSON into integers.
  factory RawAyahData.fromJson(Map<String, dynamic> json) {
    return RawAyahData(
      int.parse(json['sura'].toString()),
      int.parse(json['ayah'].toString()),
      json['text'],
    );
  }
}

class WordByWord {
  final int sura, ayah;
  final String arabic, bengali;
  // FIX 3: Removed wordId from the model since it's not in the JSON.
  // We will generate it during the database insertion process.
  WordByWord(this.sura, this.ayah, this.arabic, this.bengali);

  factory WordByWord.fromJson(Map<String, dynamic> json) {
    return WordByWord(
      json['sura'],
      json['ayah'],
      // FIX 2: Use the correct keys from the JSON file.
      json['Arabic'], // Was 'arabic'
      json['bn'],       // Was 'bengali'
    );
  }
}

Future<void> main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;

  final dbPath = p.join(Directory.current.path, 'quran.db');
  final dbFile = File(dbPath);
  if (await dbFile.exists()) {
    await dbFile.delete();
    print('Deleted existing database.');
  }

  final db = await databaseFactory.openDatabase(dbPath);
  print('Database created at: $dbPath');

  // --- Create Tables (Schema is correct, no changes needed) ---
  await db.execute('''
  CREATE TABLE ayahs (
    id INTEGER PRIMARY KEY,
    sura INTEGER NOT NULL,
    ayah INTEGER NOT NULL,
    arabic_text TEXT NOT NULL,
    UNIQUE(sura, ayah)
  )
  ''');
  await db.execute('''
  CREATE TABLE translations (
    id INTEGER PRIMARY KEY,
    sura INTEGER NOT NULL,
    ayah INTEGER NOT NULL,
    translator_name TEXT NOT NULL,
    translation_text TEXT NOT NULL
  )
  ''');
  await db.execute('''
  CREATE TABLE words (
    id INTEGER PRIMARY KEY,
    sura INTEGER NOT NULL,
    ayah INTEGER NOT NULL,
    word_id INTEGER NOT NULL,
    arabic_word TEXT NOT NULL,
    bengali_word TEXT NOT NULL
  )
  ''');
  print('Tables created.');

  // --- Load and Insert Data ---
  final batch = db.batch();

  // 1. Arabic Ayahs (This will now work with the fixed RawAyahData model)
  final arabicList = await _loadJson('assets/quran/arabic.json', RawAyahData.fromJson);
  for (var ayah in arabicList) {
    batch.insert('ayahs', {
      'sura': ayah.sura,
      'ayah': ayah.ayah,
      'arabic_text': ayah.text,
    });
  }
  print('Processed Arabic data.');

  // 2. Translations
  await _processTranslation(batch, 'assets/quran/bn_taqi.json', 'মুফতী তাকী উসমানী');
  await _processTranslation(batch, 'assets/quran/bn_mohiuddin.json', 'মাওলানা মুহিউদ্দিন খান');
  // FIX 4: Corrected the asset path typo.
  await _processTranslation(batch, 'assets/quran/bn_islamic_foundation.json', 'ইসলামিক ফাউন্ডেশন');

  // 3. Word by Word
  final wordList = await _loadJson('assets/quran/word.json', WordByWord.fromJson);

  // FIX 3 (Implementation): Generate the word_id programmatically.
  int currentSura = -1;
  int currentAyah = -1;
  int wordCounter = 1;

  for (var word in wordList) {
    if (word.sura != currentSura || word.ayah != currentAyah) {
      // When we encounter a new ayah, reset the counter.
      currentSura = word.sura;
      currentAyah = word.ayah;
      wordCounter = 1;
    }

    batch.insert('words', {
      'sura': word.sura,
      'ayah': word.ayah,
      'word_id': wordCounter, // Use the generated ID
      'arabic_word': word.arabic,
      'bengali_word': word.bengali,
    });

    wordCounter++; // Increment for the next word in the same ayah.
  }
  print('Processed Word-by-Word data.');

  await batch.commit(noResult: true);
  print('All data committed to the database successfully!');

  await db.close();
}

Future<List<T>> _loadJson<T>(
    String path, T Function(Map<String, dynamic>) fromJson) async {
  final file = File(path);
  final jsonString = await file.readAsString();
  final List<dynamic> jsonList = jsonDecode(jsonString);
  return jsonList.map((json) => fromJson(json)).toList();
}

Future<void> _processTranslation(
    Batch batch, String path, String translatorName) async {
  final translationList = await _loadJson(path, RawAyahData.fromJson);
  for (var item in translationList) {
    batch.insert('translations', {
      'sura': item.sura,
      'ayah': item.ayah,
      'translator_name': translatorName,
      'translation_text': item.text,
    });
  }
  print('Processed translation: $translatorName');
}