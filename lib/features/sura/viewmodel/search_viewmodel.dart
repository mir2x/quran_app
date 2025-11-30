import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/sura/model/ayah.dart';
import 'package:quran_app/features/sura/viewmodel/sura_viewmodel.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider.autoDispose<List<Ayah>>((ref) async {
  final query = ref.watch(searchQueryProvider);

  if (query.trim().isEmpty) {
    return [];
  }

  await Future.delayed(const Duration(milliseconds: 300));

  if (ref.read(searchQueryProvider) != query) {
    return [];
  }

  final db = await ref.watch(databaseProvider.future);

  final quranService = ref.watch(quranDataServiceProvider);

  return quranService.searchQuran(db, query);
});
