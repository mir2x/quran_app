import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FolderDownloader {
  final Dio dio = Dio();

  Future<String> getPublicUrl(String bucket, String remotePath) async {
    final url = Supabase.instance.client.storage.from(bucket).getPublicUrl(remotePath);
    return url;
  }

  Future<File> _localFile(String type, String folder, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/downloads/$type/$folder');
    if (!await downloadDir.exists()) await downloadDir.create(recursive: true);
    return File('${downloadDir.path}/$fileName');
  }

  Future<bool> allFilesExist(String type, String folder, List<String> files) async {
    for (final file in files) {
      if (!await (await _localFile(type, folder, file)).exists()) {
        return false;
      }
    }
    return true;
  }

  Future<void> downloadAllFiles({
    required String bucket,
    required String type,
    required String folder,
    required List<String> files,
    required void Function(double, int, int) onProgress,
  }) async {
    int done = 0;
    for (final file in files) {
      final remotePath = '$type/$folder/$file';
      final url = await getPublicUrl(bucket, remotePath);
      final local = await _localFile(type, folder, file);
      if (!await local.exists()) {
        await dio.download(url, local.path);
      }
      done++;
      onProgress(done / files.length, done, files.length);
    }
  }

  Future<List<String>> getLocalPaths(String type, String folder, List<String> files) async {
    final dir = await getApplicationDocumentsDirectory();
    return files.map((f) => '${dir.path}/downloads/$type/$folder/$f').toList();
  }
}

final folderDownloaderProvider = Provider((ref) => FolderDownloader());
