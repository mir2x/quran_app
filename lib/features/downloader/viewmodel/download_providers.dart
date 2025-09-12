import 'dart:io';
import 'package:dio/dio.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../../home/presentation/providers/home_providers.dart';
import '../model/download_state.dart';

Future<bool> isAssetDownloaded(String id) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('reciter_downloaded_$id') ?? false;
}

Future<void> markAsDownloaded(String id) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('reciter_downloaded_$id', true);
}

Future<String> getLocalPath(String id) async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/$id';
}


abstract class DownloadTask {
  String get id;
  String get displayName;

  Future<void> run(Ref ref, Function(int received, int total) onProgress, CancelToken cancelToken);
}

class MultiFileDownloadTask extends DownloadTask {
  @override
  final String id;
  @override
  final String displayName;
  final Map<String, String> urlToPathMap;

  MultiFileDownloadTask({
    required this.id,
    required this.displayName,
    required this.urlToPathMap,
  });

  @override
  Future<void> run(Ref ref, Function(int received, int total) onProgress, CancelToken cancelToken) async {
    final dio = Dio();
    int completed = 0;
    for (final entry in urlToPathMap.entries) {
      final file = File(entry.value);
      await file.parent.create(recursive: true);
      await dio.download(entry.key, entry.value, cancelToken: cancelToken);
      completed++;
      onProgress(completed, urlToPathMap.length);
    }
  }
}

class ZipDownloadTask extends DownloadTask {
  @override
  final String id;
  @override
  final String displayName;
  final String zipUrl;

  ZipDownloadTask({
    required this.id,
    required this.displayName,
    required this.zipUrl,
  });

  @override
  Future<void> run(Ref ref, Function(int received, int total) onProgress, CancelToken cancelToken) async {
    final notifier = ref.read(downloadStateProvider.notifier);
    final dio = Dio();
    final dirPath = await getLocalPath(id);
    final zipPath = '$dirPath.zip';

    await Directory(dirPath).create(recursive: true);

    await dio.download(zipUrl, zipPath, onReceiveProgress: onProgress, cancelToken: cancelToken);
    if (cancelToken.isCancelled) return;

    notifier.setExtracting();
    final bytes = await File(zipPath).readAsBytes();
    if (cancelToken.isCancelled) { await File(zipPath).delete(); return; }

    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      if (cancelToken.isCancelled) break;
      if (file.isFile) {
        final filePath = p.join(dirPath, p.basename(file.name));
        final outFile = File(filePath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }

    if (cancelToken.isCancelled) {
      if (await Directory(dirPath).exists()) { await Directory(dirPath).delete(recursive: true); }
    } else {
      await markAsDownloaded(id);
    }

    if (await File(zipPath).exists()) { await File(zipPath).delete(); }
  }
}

class SingleFileDownloadTask extends DownloadTask {
  @override
  final String id;
  @override
  final String displayName;
  final String fileUrl;
  final String localPath;

  SingleFileDownloadTask({
    required this.id,
    required this.displayName,
    required this.fileUrl,
    required this.localPath,
  });

  @override
  Future<void> run(Ref ref, Function(int received, int total) onProgress, CancelToken cancelToken) async {
    final dio = Dio();
    final file = File(localPath);
    await file.parent.create(recursive: true);
    await dio.download(fileUrl, localPath, onReceiveProgress: onProgress, cancelToken: cancelToken);
    if (!cancelToken.isCancelled) {
      await markAsDownloaded(id);
    }
  }
}

class DownloadNotifier extends StateNotifier<DownloadState> {
  DownloadNotifier() : super(DownloadState());

  void start(DownloadTask task) {
    state = DownloadState(status: DownloadStatus.preparing, taskName: task.displayName);
  }

  void updateProgress({int? completedItems, int? totalItems, int? receivedSize, int? totalSize}) {
    state = state.copyWith(
      status: DownloadStatus.downloading,
      completedItems: completedItems,
      totalItems: totalItems,
      receivedSize: receivedSize,
      totalSize: totalSize,
    );
  }

  void setExtracting() => state = state.copyWith(status: DownloadStatus.extracting);
  void setError(String message) => state = state.copyWith(status: DownloadStatus.error, errorMessage: message);
  void setCancelled() => state = state.copyWith(status: DownloadStatus.cancelled);
  void setCompleted() => state = state.copyWith(status: DownloadStatus.completed);
  void reset() => state = DownloadState();
}

final downloadStateProvider = StateNotifierProvider<DownloadNotifier, DownloadState>((ref) => DownloadNotifier());

class DownloadManager {
  final Ref _ref;
  CancelToken? _cancelToken;
  bool _isDownloading = false;

  DownloadManager(this._ref);

  Future<bool> startDownload(DownloadTask task) async {
    if (_isDownloading) {
      print("Another download is already in progress.");
      return false; // Indicate failure if a download is already active
    }
    _isDownloading = true;
    _cancelToken = CancelToken();
    final notifier = _ref.read(downloadStateProvider.notifier);
    notifier.start(task);

    try {
      if (task is MultiFileDownloadTask) {
        await task.run(_ref, (completed, total) {
          notifier.updateProgress(completedItems: completed, totalItems: total);
        }, _cancelToken!);
      } else {
        await task.run(_ref, (received, total) {
          notifier.updateProgress(receivedSize: received, totalSize: total);
        }, _cancelToken!);
      }

      if (_cancelToken?.isCancelled ?? false) {
        notifier.setCancelled();
        return false; // Return false on cancellation
      }

      notifier.setCompleted();
      await _ref.read(quranEditionProvider.notifier).refreshDownloadStatus();
      return true; // Return true on successful completion

    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        notifier.setCancelled();
      } else {
        notifier.setError("A network error occurred.");
      }
      return false; // Return false on any error
    } catch (e) {
      notifier.setError("An unexpected error occurred: $e");
      return false; // Return false on any error
    } finally {
      _isDownloading = false;
      _cancelToken = null;
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel("User cancelled.");
  }
}

final downloadManagerProvider = Provider((ref) => DownloadManager(ref));