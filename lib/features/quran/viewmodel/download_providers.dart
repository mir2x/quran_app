// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../model/download_progress.dart';
// import 'audio_providers.dart';
//
// class DownloadProgressNotifier extends StateNotifier<DownloadProgress> {
//   DownloadProgressNotifier() : super(DownloadProgress());
//
//   void start(int total) =>
//       state = DownloadProgress(totalCount: total);
//
//   void increment() =>
//       state = DownloadProgress(
//         downloadedCount: state.downloadedCount + 1,
//         totalCount: state.totalCount,
//       );
//
//   void setError(String errorMsg) =>
//       state = DownloadProgress(
//         error: errorMsg,
//         totalCount: state.totalCount,
//         downloadedCount: state.downloadedCount,
//       );
//
//   void reset() => state = DownloadProgress();
// }
//
// final downloadProgressProvider =
// StateNotifierProvider<DownloadProgressNotifier, DownloadProgress>(
//         (ref) => DownloadProgressNotifier());
//
// class DownloadManager {
//   final Dio _dio = Dio();
//   final Ref _ref;
//   DownloadManager(this._ref);
//
//   Future<bool> downloadAyahs({
//     required String reciterId,
//     required int sura,
//     required List<int> ayahsToDownload,
//   }) async {
//     if (ayahsToDownload.isEmpty) {
//       return true;
//     }
//
//     final audioSource = _ref.read(audioDataSourceProvider);
//     final audioFileManager = _ref.read(audioFileManagerProvider);
//     final progressNotifier = _ref.read(downloadProgressProvider.notifier);
//
//     final suraAudioData = await audioSource.getSuraAudioUrls(reciterId, sura);
//     if (suraAudioData == null) {
//       progressNotifier.setError('Could not fetch audio info.');
//       return false;
//     }
//
//     final Map<int, String> remoteUrlsForAyahs = {};
//     for (int ayahNum in ayahsToDownload) {
//       if (ayahNum > 0 && ayahNum <= suraAudioData.urls.length) {
//         remoteUrlsForAyahs[ayahNum] = suraAudioData.urls[ayahNum - 1];
//       }
//     }
//
//     if (remoteUrlsForAyahs.isEmpty) {
//       progressNotifier.setError('No audio URLs found for selected ayahs.');
//       return false;
//     }
//
//     progressNotifier.start(remoteUrlsForAyahs.length);
//
//     try {
//       for (final entry in remoteUrlsForAyahs.entries) {
//         final int ayah = entry.key;
//         final String remoteUrl = entry.value;
//         final localPath = await audioFileManager.getLocalPathForAyah(reciterId, sura, ayah);
//
//         final File file = File(localPath);
//         if (!await file.parent.exists()) {
//           await file.parent.create(recursive: true);
//         }
//
//         await _dio.download(remoteUrl, localPath);
//         progressNotifier.increment();
//       }
//       return true;
//     } catch (e) {
//       print('Download failed for ayahs $ayahsToDownload: $e');
//       progressNotifier.setError('Download failed.');
//       return false;
//     }
//   }
//
//   Future<bool> downloadSura({required String reciterId, required int sura}) async {
//     final audioSource = _ref.read(audioDataSourceProvider);
//     final audioFileManager = _ref.read(audioFileManagerProvider);
//     final progressNotifier = _ref.read(downloadProgressProvider.notifier);
//
//     final suraAudioData = await audioSource.getSuraAudioUrls(reciterId, sura);
//     if (suraAudioData == null) {
//       progressNotifier.setError('Could not fetch audio info.');
//       return false;
//     }
//
//     final remoteUrls = suraAudioData.urls;
//     progressNotifier.start(remoteUrls.length);
//
//     try {
//       for (int i = 0; i < remoteUrls.length; i++) {
//         final localPath = await audioFileManager.getLocalPathForAyah(reciterId, sura, i + 1);
//         final File file = File(localPath);
//         if (!await file.parent.exists()) {
//           await file.parent.create(recursive: true);
//         }
//         await _dio.download(remoteUrls[i], localPath);
//         progressNotifier.increment();
//       }
//       return true;
//     } catch (e) {
//       print('Download failed: $e');
//       progressNotifier.setError('Download failed.');
//       final suraDir = await audioFileManager.getSuraDirectory(reciterId, sura);
//       if (await suraDir.exists()) await suraDir.delete(recursive: true);
//       return false;
//     }
//   }
// }
// final downloadManagerProvider = Provider((ref) => DownloadManager(ref));