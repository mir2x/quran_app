import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/quran_old/presentation/providers/quran_notifiers.dart';
import 'package:quran_app/features/quran_old/presentation/providers/quran_state.dart';


final quranProvider =
StateNotifierProvider<QuranNotifier, QuranState>((ref) => QuranNotifier());