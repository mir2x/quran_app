// file: models/download_state.dart

// An enum to clearly define the current status of the download process.
enum DownloadStatus {
  idle,       // Nothing is happening
  preparing,  // Preparing files or fetching URLs
  downloading,
  extracting, // For ZIP files
  completed,
  error,
  cancelled,
}

class DownloadState {
  final DownloadStatus status;
  final String taskName; // e.g., "Mishary Alafasy Audio"

  // For multi-file progress (e.g., Ayahs)
  final int totalItems;
  final int completedItems;

  // For byte-level progress (e.g., Zip files, DB files)
  final int totalSize;
  final int receivedSize;

  final String? errorMessage;

  DownloadState({
    this.status = DownloadStatus.idle,
    this.taskName = '',
    this.totalItems = 0,
    this.completedItems = 0,
    this.totalSize = 0,
    this.receivedSize = 0,
    this.errorMessage,
  });

  // Helper method to create a copy with new values.
  DownloadState copyWith({
    DownloadStatus? status,
    String? taskName,
    int? totalItems,
    int? completedItems,
    int? totalSize,
    int? receivedSize,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DownloadState(
      status: status ?? this.status,
      taskName: taskName ?? this.taskName,
      totalItems: totalItems ?? this.totalItems,
      completedItems: completedItems ?? this.completedItems,
      totalSize: totalSize ?? this.totalSize,
      receivedSize: receivedSize ?? this.receivedSize,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}