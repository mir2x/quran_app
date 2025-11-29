enum DownloadStatus {
  idle,
  preparing,
  downloading,
  extracting,
  completed,
  error,
  cancelled,
}

class DownloadState {
  final DownloadStatus status;
  final String taskName;
  final int totalItems;
  final int completedItems;
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
