import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'package:device_preview/device_preview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const ProviderScope(child: QuranApp()),
    ),
  );
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (_, child) {
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
      },
    );
  }
}
