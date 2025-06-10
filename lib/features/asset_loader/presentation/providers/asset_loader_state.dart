class AssetLoaderState {
  final double progress;
  final String status;
  final bool done;
  final String? error;

  const AssetLoaderState({
    required this.progress,
    required this.status,
    required this.done,
    this.error,
  });

  AssetLoaderState copyWith({
    double? progress,
    String? status,
    bool? done,
    String? error,
  }) {
    return AssetLoaderState(
      progress: progress ?? this.progress,
      status: status ?? this.status,
      done: done ?? this.done,
      error: error,
    );
  }
}