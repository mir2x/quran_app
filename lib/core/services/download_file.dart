import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';          // ← debugPrint
import 'package:path_provider/path_provider.dart';

class EditionStorage {
  EditionStorage._(this.root);
  final Directory root;

  /// App-private “Quran editions” root, e.g.
  /// Android:  /data/user/0/<package>/files/quran_editions
  /// iOS:      <App Sandbox>/Library/Application Support/quran_editions
  static Future<EditionStorage> instance() async {
    final dir  = await getApplicationSupportDirectory();
    final root = Directory('${dir.path}/quran_editions');
    if (!await root.exists()) await root.create(recursive: true);

    debugPrint('[EditionStorage] root → ${root.path}');
    return EditionStorage._(root);
  }

  Directory dirFor(String editionId) => Directory('${root.path}/$editionId');

  Future<bool> isDownloaded(String editionId) async {
    final path = '${dirFor(editionId).path}/ayah_boxes.json';
    final exists = await File(path).exists();
    debugPrint('[EditionStorage] isDownloaded($editionId) → $exists');
    return exists;
  }
}

class EditionDownloader {
  EditionDownloader(this._dio, this._storage);
  final Dio _dio;
  final EditionStorage _storage;

  /// Downloads the ZIP, emits progress, unzips, cleans temp.
  Future<void> download(
      String editionId,
      String zipUrl, {
        required void Function(int recv, int total) onProgress,
      }) async {
    final tmpZip = File('${_storage.root.path}/$editionId.zip');

    debugPrint('[Downloader] GET  $zipUrl');
    debugPrint('[Downloader] --> $tmpZip');

    await _dio.download(
      zipUrl,
      tmpZip.path,
      onReceiveProgress: (r, t) {
        debugPrint(
          '[Downloader] progress '
              '${(r / 1024 / 1024).toStringAsFixed(1)} / '
              '${(t / 1024 / 1024).toStringAsFixed(1)} MB',
        );
      },
      options: Options(responseType: ResponseType.bytes),
      deleteOnError: true,
    );

    // ─── unzip ───
    debugPrint('[Downloader] unzip → ${_storage.dirFor(editionId).path}');
    final bytes    = await tmpZip.readAsBytes();
    final archive  = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final outPath = '${_storage.dirFor(editionId).path}/${file.name}';
      if (file.isFile) {
        debugPrint('        file  ${file.name}');
        final outFile = await File(outPath).create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        debugPrint('        dir   ${file.name}/');
        await Directory(outPath).create(recursive: true);
      }
    }

    await tmpZip.delete();
    debugPrint('[Downloader] ✔ finished  $editionId');
  }
}
