sealed class DownloadState {
  const DownloadState();

  const factory DownloadState.notDownloaded()                         = NotDownloaded;
  const factory DownloadState.downloading({required int received,
    required int total})       = Downloading;
  const factory DownloadState.downloaded()                            = Downloaded;
  const factory DownloadState.failed(String msg)                      = Failed;
}

/* ── public subclasses (no underscore) ─────────────────────────── */
class NotDownloaded extends DownloadState { const NotDownloaded(); }

class Downloading extends DownloadState {
  const Downloading({required this.received, required this.total});
  final int received, total;
  double get percent => total == 0 ? 0 : received / total;
}

class Downloaded extends DownloadState { const Downloaded(); }

class Failed extends DownloadState {
  const Failed(this.msg);
  final String msg;
}
