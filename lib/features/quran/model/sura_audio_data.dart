class SuraAudioData {
  final List<String> urls;
  final int totalAyahs;
  final num totalDownloadSizeBytes;
  final num totalDownloadSizeMB;

  SuraAudioData({
    required this.urls,
    required this.totalAyahs,
    required this.totalDownloadSizeBytes,
    required this.totalDownloadSizeMB,
  });

  factory SuraAudioData.fromJson(Map<String, dynamic> json) {
    return SuraAudioData(
      urls: List<String>.from(json['urls']),
      totalAyahs: json['totalAyahs'],
      totalDownloadSizeBytes: json['totalDownloadSizeBytes'],
        totalDownloadSizeMB: json['totalDownloadSizeMB'],
    );
  }
}