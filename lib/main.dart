import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/home/presentation/screens/home_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ntgkoryrbfyhcbqfnsbx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im50Z2tvcnlyYmZ5aGNicWZuc2J4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTIyMDQwNSwiZXhwIjoyMDY0Nzk2NDA1fQ.8E8CkezPBhpKZ8YIZjcCc9HCiUH1tpvm4-1iwEXTDh4',
  );
  await logReciterFolder('maher_muaiqly');
  runApp(const ProviderScope(child: QuranApp()));
}

Future<void> logReciterFolder(String reciterId) async {
  final dir = await getApplicationDocumentsDirectory();
  final reciterDir = Directory('${dir.path}/$reciterId');

  if (!await reciterDir.exists()) {
    print('❌ Directory does not exist: ${reciterDir.path}');
    return;
  }

  print('📂 Contents of ${reciterDir.path}:');
  await for (var entity in reciterDir.list(recursive: true, followLinks: false)) {
    final type = entity is File ? '📄 File' : '📁 Folder';
    print('  $type: ${entity.path}');
  }
}


class QuranApp extends StatelessWidget {
  const QuranApp({super.key});


  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'কুরআন মজীদ',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 57, 93, 79),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 57, 93, 79),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 22),
        ),
        bottomAppBarTheme: const BottomAppBarTheme(
          color: Color.fromARGB(255, 57, 93, 79),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
