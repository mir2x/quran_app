// tool/convert_json_to_db.dart
import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p; // <-- 1. Import the path package

Future<void> main() async {
  // --- SETUP ---
  final jsonFilePath = '/home/mir/dev/projects/data-extractor/tafsir_output/tafsir_taqi_usmani_bn.json';

  // --- ROBUST PATH RESOLUTION ---
  // 2. Calculate the absolute path to the database file
  // This makes the script independent of the current working directory.
  final scriptPath = Platform.script.toFilePath(); // Gets path to this script file
  final projectRoot = p.dirname(p.dirname(scriptPath)); // Goes up two levels (tool -> project root)
  final dbFilePath = p.join(projectRoot, 'assets', 'tafsir', 'tafsir_taqi_usmani_bn.db');
  // --- END OF ROBUST PATH RESOLUTION ---


  // Initialize FFI for desktop use
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;

  print('Deleting old database file if it exists...');
  final dbFile = File(dbFilePath);
  if (await dbFile.exists()) {
    await dbFile.delete();
  }
  // Ensure the directory exists
  await dbFile.parent.create(recursive: true);

  // The rest of your code remains exactly the same...
  final db = await databaseFactory.openDatabase(dbFilePath);
  print('Database created at $dbFilePath'); // This will now print the full, absolute path

  // --- CREATE TABLE AND INDEX ---
  await db.execute('''
    CREATE TABLE tafsir (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sura INTEGER NOT NULL,
      ayah INTEGER NOT NULL,
      text TEXT NOT NULL
    )
  ''');
  print('Table "tafsir" created.');

  await db.execute('CREATE INDEX idx_sura_ayah ON tafsir (sura, ayah)');
  print('Index on (sura, ayah) created.');

  // --- READ JSON AND INSERT DATA ---
  print('Reading JSON file...');
  final jsonString = await File(jsonFilePath).readAsString();
  final List<dynamic> tafsirList = jsonDecode(jsonString);
  print('JSON parsed. Found ${tafsirList.length} entries.');

  final batch = db.batch();
  int count = 0;
  for (var item in tafsirList) {
    batch.insert('tafsir', {
      'sura': item['sura'],
      'ayah': item['ayah'],
      'text': item['tafsir'],
    });
    count++;
    if (count % 1000 == 0) {
      await batch.commit(noResult: true);
      print('Inserted $count records...');
    }
  }
  await batch.commit(noResult: true);
  print('Finished inserting all $count records.');

  // --- CLEANUP ---
  await db.close();
  print('Database closed. Conversion complete!');
}