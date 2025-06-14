
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/services/download_file.dart';
import '../model/download_state.dart';
import '../model/edition.dart';


/// 1️⃣  Hard-coded catalogue for the demo
final catalogueProvider = Provider<List<QuranEdition>>((_) => const [
  QuranEdition(
    id: 'colorful_tajweed',
    name: 'Colorful Tajweed',
    zipUrl:
    'https://ntgkoryrbfyhcbqfnsbx.supabase.co/storage/v1/object/public/assets/colorful_tajweed/asset.zip',
    sizeBytes: 8346364,
    imageWidth: 720,
    imageHeight: 1057,
  ),
  // QuranEdition(
  //   id: 'madina_mushaf',
  //   name: 'Madina Mushaf',
  //   zipUrl:
  //   'https://xyz.supabase.co/storage/v1/object/public/assets/madina_mushaf/madina_mushaf.zip',
  //   sizeBytes: 280000000,
  // ),
]);

/// 2️⃣  Singleton helpers
final storageProvider = FutureProvider<EditionStorage>(
        (_) => EditionStorage.instance());
final downloaderProvider = Provider<EditionDownloader>((ref) {
  final storage = ref.watch(storageProvider).value!;
  return EditionDownloader(Dio(), storage);
});

/// 3️⃣  Per-edition download state
class DownloadNotifier extends StateNotifier<DownloadState> {
  DownloadNotifier(this.edition, this.ref) : super(const DownloadState.notDownloaded()) {
    _init();
  }

  final QuranEdition edition;
  final Ref ref;

  Future<void> _init() async {
    final storage = await ref.read(storageProvider.future);
    if (await storage.isDownloaded(edition.id)) {
      state = const DownloadState.downloaded();
    }
  }

  Future<void> startDownload() async {
    if (state is! NotDownloaded) return;
    final storage   = await ref.read(storageProvider.future);
    final downloader = ref.read(downloaderProvider);

    state = const DownloadState.downloading(received: 0, total: 1);
    try {
      await downloader.download(
        edition.id,
        edition.zipUrl,
        onProgress: (r, t) =>
        state = DownloadState.downloading(received: r, total: t),
      );
      state = const DownloadState.downloaded();
    } catch (e) {
      state = DownloadState.failed(e.toString());
    }
  }
}

final downloadStateProvider =
StateNotifierProvider.family<DownloadNotifier, DownloadState, QuranEdition>(
        (ref, ed) => DownloadNotifier(ed, ref));
