import 'package:flutter_riverpod/flutter_riverpod.dart';

final arabicFontProvider = StateProvider<String>((ref) => 'Al Mushaf Quran');
final arabicFontSizeProvider = StateProvider<double>((ref) => 28.0);


final bengaliFontProvider = StateProvider<String>((ref) => 'SolaimanLipi');
final bengaliFontSizeProvider = StateProvider<double>((ref) => 16.0);