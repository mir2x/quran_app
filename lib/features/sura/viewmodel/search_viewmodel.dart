import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/sura/model/ayah.dart';
import 'package:quran_app/features/sura/viewmodel/sura_viewmodel.dart';

// Service to perform the search logic
class SearchService {
  final QuranDataService _quranDataService;
  List<Ayah>? _allAyahs;

  SearchService(this._quranDataService);

  Future<void> _init() async {
    _allAyahs ??= await _quranDataService.loadAllAyahs();
  }

  Future<List<Ayah>> search(String query) async {
    await _init(); // Ensure data is loaded

    if (query.trim().isEmpty) {
      return [];
    }

    final normalizedQuery = query.toLowerCase();
    final Set<Ayah> results = {};

    for (final ayah in _allAyahs!) {
      // Search in Arabic text
      if (ayah.arabicText.toLowerCase().contains(normalizedQuery)) {
        results.add(ayah);
      }

      // Search in translations
      for (final translation in ayah.translations) {
        if (translation.text.toLowerCase().contains(normalizedQuery)) {
          results.add(ayah);
        }
      }
    }
    return results.toList()
      ..sort((a, b) {
        if (a.sura != b.sura) return a.sura.compareTo(b.sura);
        return a.ayah.compareTo(b.ayah);
      });
  }
}

// Provider for the SearchService instance
final searchServiceProvider = Provider<SearchService>((ref) {
  // Use ref.watch to get the existing QuranDataService instance
  final quranService = ref.watch(quranDataServiceProvider);
  return SearchService(quranService);
});

// Provider to hold the current search query text
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider to get the search results based on the query
final searchResultsProvider = FutureProvider.autoDispose<List<Ayah>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) {
    return [];
  }
  final searchService = ref.watch(searchServiceProvider);
  return searchService.search(query);
});

// We need a provider for the QuranDataService itself to be used by others
final quranDataServiceProvider = Provider<QuranDataService>((ref) => QuranDataService());