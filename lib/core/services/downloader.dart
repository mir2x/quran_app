import 'dart:io';
import 'package:dio/dio.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/quran/model/reciter_asset.dart';

Future<bool> isReciterDownloaded(String reciterId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('reciter_downloaded_$reciterId') ?? false;
}

Future<void> markReciterAsDownloaded(String reciterId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('reciter_downloaded_$reciterId', true);
}

Future<String> getLocalReciterPath(String reciterId) async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/$reciterId';
}

Future<void> downloadAndExtractReciter(
    ReciterAsset reciter,
    void Function(int received, int total) onProgress,
    ) async {
  final dirPath = await getLocalReciterPath(reciter.id);
  final zipPath = '$dirPath.zip';

  await Directory(dirPath).create(recursive: true);

  final dio = Dio();
  await dio.download(
    reciter.zipUrl,
    zipPath,
    onReceiveProgress: onProgress,
  );

  final bytes = File(zipPath).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  for (final file in archive) {
    final filePath = '$dirPath/${file.name}';
    if (file.isFile) {
      final outFile = File(filePath)..createSync(recursive: true);
      outFile.writeAsBytesSync(file.content as List<int>);
    } else {
      Directory(filePath).createSync(recursive: true);
    }
  }

  await File(zipPath).delete();
  await markReciterAsDownloaded(reciter.id);
}
