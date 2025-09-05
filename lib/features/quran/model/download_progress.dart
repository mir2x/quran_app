class DownloadProgress {
  final int downloadedCount;
  final int totalCount;
  final String? error;

  DownloadProgress({
    this.downloadedCount = 0,
    this.totalCount = 0,
    this.error,
  });

  double get percentage =>
      totalCount == 0 ? 0.0 : downloadedCount / totalCount;
}
