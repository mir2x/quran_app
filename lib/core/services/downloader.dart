import 'dart:io';
import 'package:dio/dio.dart';
import 'package:archive/archive_io.dart';
import 'fileChecker.dart';

Future<void> downloadAndExtract(
    final String id,
    final String url,
    void Function(int received, int total) onProgress,
    ) async {
  final dirPath = await getLocalPath(id);         // Target dir: /.../reciter_name/
  final zipPath = '$dirPath.zip';

  await Directory(dirPath).create(recursive: true);

  final dio = Dio();
  await dio.download(
    url,
    zipPath,
    onReceiveProgress: onProgress,
  );

  final bytes = File(zipPath).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  for (final file in archive) {
    if (file.isFile) {
      // Extract filename only (remove any folders in the zip path)
      final flattenedFileName = file.name.split(Platform.pathSeparator).last;
      final filePath = '$dirPath/$flattenedFileName';

      final outFile = File(filePath)..createSync(recursive: true);
      outFile.writeAsBytesSync(file.content as List<int>);
    }
  }

  await File(zipPath).delete();
  await markAsDownloaded(id);
}
