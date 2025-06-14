import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/quran_edition.dart';

Future<List<QuranEdition>> getQuranEditionData() async {
  final editions = [
    {
      'id': 'hafezi',
      'title': 'হাফিজি কুরআন',
      'cover': 'assets/image/front_page/hafezi.jpg',
      'url' : '',
      'sizeBytes': 100,
      'width': 2090,
      'height': 3280,
    },
    {
      'id': 'colorful_tajweed',
      'title': 'রঙিন\nতাজবীদ কুরআন',
      'cover': 'assets/image/front_page/colorful_tajweed.jpg',
      'url' : 'https://ntgkoryrbfyhcbqfnsbx.supabase.co/storage/v1/object/public/assets/colorful_tajweed/asset.zip',
      'sizeBytes': 8346364,
      'width': 720,
      'height': 1057,
    },
    {
      'id': 'saudi_hafezi',
      'title': 'হাফিজি কুরআন\n(সৌদি প্রিন্ট)',
      'cover': 'assets/image/front_page/hafezi-saudi.jpg',
      'url' : '',
      'sizeBytes': 100,
      'width': 1455,
      'height': 2125,
    },
    {
      'id': 'imdadia_hafezi',
      'title': 'হাফিজি কুরআন\n(এমদাদিয়া লাইব্রেরী)',
      'cover': 'assets/image/front_page/imdadia_hafezi.jpg',
      'url' : '',
      'sizeBytes': 100,
      'width': 648,
      'height': 1011,
    },
    {
      'id': 'madani',
      'title': 'মাদানী কুরআন\n(উসমানী প্রিন্ট)',
      'cover': 'assets/image/front_page/madani.jpg',
      'url' : '',
      'sizeBytes': 100,
      'width': 1361,
      'height': 2430,
    },
    {
      'id': 'nurani',
      'title': 'নূরানী কুরআন\n(এমদাদিয়া লাইব্রেরী)',
      'cover': 'assets/image/front_page/nurani.jpg',
      'url' : '',
      'sizeBytes': 100,
      'width': 1674,
      'height': 2584,
    },
    {
      'id': 'colorful_hafezi',
      'title': 'রঙিন হাফিজি',
      'cover': 'assets/image/front_page/colorful_hafezi.jpg',
      'url' : '',
      'sizeBytes': 100,
      'width': 1829,
      'height': 2817,
    },
  ];

  return Future.wait(editions.map(QuranEdition.fromMap));
}

class QuranEditionNotifier extends StateNotifier<List<QuranEdition>> {
  QuranEditionNotifier() : super([]) {
    loadEditions(); // Ensure editions are loaded when the provider is initialized
  }

  Future<void> loadEditions() async {
    final data = await getQuranEditionData(); // Load editions
    print(data);
    state = data;  // Update the state with the loaded editions
  }

  void markAsDownloaded(String id) {
    state = [
      for (final e in state)
        if (e.id == id) e.copyWith(isDownloaded: true) else e
    ];
  }
}


final quranEditionProvider =
StateNotifierProvider<QuranEditionNotifier, List<QuranEdition>>(
        (ref) => QuranEditionNotifier());