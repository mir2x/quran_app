import 'package:quran_app/core/services/fileChecker.dart';

class QuranEdition {
  final String id;
  final String title;
  final String coverImagePath;
  final String url;
  final int sizeBytes;
  final int imageWidth;
  final int imageHeight;
  final String imageExt;
  final bool isDownloaded;


  const QuranEdition({
    required this.id,
    required this.title,
    required this.coverImagePath,
    required this.url,
    required this.sizeBytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageExt,
    this.isDownloaded = false,
  });

  QuranEdition copyWith({
    bool? isDownloaded,
  }) {
    return QuranEdition(
      id: id,
      title: title,
      coverImagePath: coverImagePath,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      imageExt: imageExt,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      url: url,
      sizeBytes: sizeBytes,
    );
  }

  static Future<QuranEdition> fromMap(Map<String, dynamic> map) async {
    final downloaded = await isAssetDownloaded(map['id']);
    return QuranEdition(
      id: map['id'],
      title: map['title'],
      coverImagePath: map['cover'],
      url: map['url'],
      sizeBytes: map['sizeBytes'],
      imageWidth: map['width'],
      imageHeight: map['height'],
      imageExt: map['ext'],
      isDownloaded: downloaded,
    );
  }
}
