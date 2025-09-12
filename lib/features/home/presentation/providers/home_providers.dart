import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/quran_edition.dart';
// We don't need to import fileChecker here because the model handles it.

Future<List<QuranEdition>> getQuranEditionData() async {
  final editions = [
    {
      'id': 'imdadia_hafezi',
      'title': 'হাফিজি কুরআন\n(এমদাদিয়া লাইব্রেরী)',
      'cover': 'assets/image/front_page/imdadia_hafezi.jpg',
      'url': 'https://www.dropbox.com/scl/fi/r2qeg0pktyg8cunmc0yfw/imdadia_hafezi.zip?rlkey=1kp1pftw0if70ffaowkmyp9j4&st=8q0y0tsy&dl=1',
      'sizeBytes': 78614813,
      'width': 1152,
      'height': 2048,
      'ext': 'jpg',
    },
    {
      'id': 'hafezi',
      'title': 'হাফিজি কুরআন',
      'cover': 'assets/image/front_page/hafezi.jpg',
      'url': 'https://www.dropbox.com/scl/fi/bj7wjg76a6awhffbph3d5/hafezi.zip?rlkey=4em4vz1qydsj4qy5gxizajd4z&st=7qwdtwln&dl=1',
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
    {
      'id': 'madani',
      'title': 'মাদানী কুরআন\n(উসমানী প্রিন্ট)',
      'cover': 'assets/image/front_page/madani.png',
      'url': 'https://www.dropbox.com/scl/fi/l4par4g39qw6pa0l3tv4s/madani.zip?rlkey=yi96sa82o44dbjbvyo69scwbt&st=4upl6ivq&dl=1',
      'sizeBytes': 125700626,
      'width': 1352,
      'height': 2170,
      'ext': 'png',
    },
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
      'url' : 'https://www.dropbox.com/scl/fi/5o7v4h796ke75t090ngmg/colorful_hafezi.zip?rlkey=msix61njs8p33uy6bbo9ziant&st=d48fd6d0&dl=1',
      'sizeBytes': 162361420,
      'width': 560,
      'height': 829,
      'ext': 'jpg',
    },
  ];

  // This one-liner is now perfect. It will call `QuranEdition.fromMap` for each item,
  // which in turn calls `isAssetDownloaded` for each one.
  return Future.wait(editions.map(QuranEdition.fromMap));
}

class QuranEditionNotifier extends StateNotifier<List<QuranEdition>> {
  QuranEditionNotifier() : super([]) {
    // Load the initial data when the provider is first created.
    // This will correctly set the initial downloaded status for all items.
    refreshDownloadStatus();
  }

  /// Re-fetches all edition data and re-checks the download status for each one.
  /// This is the method the DownloadManager will call.
  Future<void> refreshDownloadStatus() async {
    // Simply re-run the original async loading function.
    // This re-builds the entire list by calling fromMap on every item,
    // which re-checks SharedPreferences.
    final data = await getQuranEditionData();
    // Update the state with the freshly-checked list.
    state = data;
  }
}

final quranEditionProvider =
StateNotifierProvider<QuranEditionNotifier, List<QuranEdition>>((ref) {
  return QuranEditionNotifier();
});