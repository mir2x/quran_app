import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/quran_edition.dart';

Future<List<QuranEdition>> getQuranEditionData() async {
  final editions = [
    {
      'id': 'imdadia_hafezi',
      'title': 'হাফিজি কুরআন\n(এমদাদিয়া লাইব্রেরী)',
      'cover': 'assets/image/front_page/imdadia_hafezi.jpg',
      'url': 'https://www.dropbox.com/scl/fi/x5sek3nub8ymhjeqvpen5/hafizi_emdadia.zip?rlkey=gy4wxd1u5bzx3bkxnt9zeyvv3&st=1s5idrg4&dl=1',
      'sizeBytes': 78614813,
      'width': 1152,
      'height': 2048,
      'ext': 'jpg',
    },
    {
      'id': 'hafezi',
      'title': 'হাফিজি কুরআন',
      'cover': 'assets/image/front_page/hafezi.jpg',
      'url': 'https://www.dropbox.com/scl/fi/8e30xqwmszu2zs27daty5/hafiz_saudi.zip?rlkey=5fhqmx6cub7viuz95fn7lrcp2&st=2jo3b362&dl=1',
      'sizeBytes': 120611119,
      'width': 1152,
      'height': 2048,
      'ext': 'png',
    },
    {
      'id': 'colorful_tajweed',
      'title': 'রঙিন\nতাজবীদ কুরআন',
      'cover': 'assets/image/front_page/colorful_tajweed.png',
      'url': 'https://www.dropbox.com/scl/fi/gclxaa18us3ev5fegbduj/colorful_tajweed.zip?rlkey=jycatywins6kor34hlbm6q8nm&st=b7gj9uk7&dl=1',
      'sizeBytes': 78145231,
      'width': 720,
      'height': 1057,
      'ext': 'png',
    },
    // {
    //   'id': 'saudi_hafezi',
    //   'title': 'হাফিজি কুরআন\n(সৌদি প্রিন্ট)',
    //   'cover': 'assets/image/front_page/hafezi-saudi.jpg',
    //   'url' : '',
    //   'sizeBytes': 100,
    //   'width': 1455,
    //   'height': 2125,
    //   'ext': 'jpg',
    // },
    // {
    //   'id': 'madani',
    //   'title': 'মাদানী কুরআন\n(উসমানী প্রিন্ট)',
    //   'cover': 'assets/image/front_page/madani.png',
    //   'url': 'https://www.dropbox.com/scl/fi/73qsbv40fpoct0k5ilq39/madani.zip?rlkey=y9sqb6bhsxwb1gk1g6af3jzz3&st=utmtjuj6&dl=1',
    //   'sizeBytes': 125878207,
    //   'width': 1352,
    //   'height': 2170,
    //   'ext': 'png',
    // },
    {
      'id': 'nurani',
      'title': 'নূরানী কুরআন\n(এমদাদিয়া লাইব্রেরী)',
      'cover': 'assets/image/front_page/nurani.jpg',
      'url': 'https://www.dropbox.com/scl/fi/pzzfjjfj2gxaj2uhffgmo/nurani.zip?rlkey=ovyzvi8awyx8x86nurlwrpy6z&st=ni7eo0o4&dl=1',
      'sizeBytes': 106934272,
      'width': 670,
      'height': 996,
      'ext': 'png',
    },
    {
      'id': 'colorful_hafezi',
      'title': 'রঙিন হাফিজি',
      'cover': 'assets/image/front_page/colorful_hafezi.jpg',
      'url' : 'https://drive.usercontent.google.com/download?id=1WtEMPCoW1mQ1UEwpouXZA4nZpxZFdaye&export=download&authuser=3&confirm=t&uuid=1fcbdca0-5851-4672-9f48-7deae2acbfc8&at=AN8xHooJMMiwaL6fjWUklId5DnKD:1750939614843',
      'sizeBytes': 162369536,
      'width': 560,
      'height': 829,
      'ext': 'jpg',
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