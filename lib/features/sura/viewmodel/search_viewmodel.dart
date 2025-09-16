import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/sura/model/ayah.dart';
import 'package:quran_app/features/sura/viewmodel/sura_viewmodel.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
FutureProvider.autoDispose<List<Ayah>>((ref) async {
  // Watch the query provider as before.
  final query = ref.watch(searchQueryProvider);

  // If the query is empty, don't bother searching.
  if (query.trim().isEmpty) {
    return [];
  }

  // DEBOUNCE: Wait for the user to stop typing for 300ms.
  await Future.delayed(const Duration(milliseconds: 300));

  // --- THIS IS THE CORRECTED LINE ---
  // If the query has changed while we were waiting, this execution is stale. Abort it.
  // This is the correct and sufficient way to handle the race condition.
  if (ref.read(searchQueryProvider) != query) {
    return [];
  }

  // Get the database instance.
  final db = await ref.watch(databaseProvider.future);

  // Get the single instance of our data service.
  final quranService = ref.watch(quranDataServiceProvider);

  // Call the optimized search method.
  return quranService.searchQuran(db, query);
});