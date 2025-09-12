import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/download_state.dart';
import '../viewmodel/download_providers.dart';


void showDownloadDialog(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  final status = container.read(downloadStateProvider).status;
  if (status == DownloadStatus.completed || status == DownloadStatus.idle || status == DownloadStatus.error) {
    container.read(downloadStateProvider.notifier).reset();
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const DownloadDialog(),
  );
}

class DownloadDialog extends ConsumerWidget {
  const DownloadDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(downloadStateProvider);

    ref.listen<DownloadState>(downloadStateProvider, (previous, next) {
      if (next.status == DownloadStatus.completed || next.status == DownloadStatus.cancelled) {
        if(Navigator.canPop(context)) Navigator.of(context).pop();
      }
    });

    Widget content;
    List<Widget> actions = [];

    switch (state.status) {
      case DownloadStatus.error:
        content = Text(state.errorMessage ?? "An unknown error occurred.");
        actions = [ TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK")) ];
        break;
      case DownloadStatus.extracting:
        content = const Row(children: [ CircularProgressIndicator(), SizedBox(width: 20), Text("Extracting files...") ]);
        break;
      case DownloadStatus.preparing:
        content = const Row(children: [ CircularProgressIndicator(), SizedBox(width: 20), Text("Preparing download...") ]);
        break;
      case DownloadStatus.downloading:
        final bool isMultiFile = state.totalItems > 0;
        final progressValue = isMultiFile
            ? (state.totalItems > 0 ? state.completedItems / state.totalItems : null)
            : (state.totalSize > 0 ? state.receivedSize / state.totalSize : null);
        final progressText = isMultiFile
            ? 'Downloaded ${state.completedItems} / ${state.totalItems}'
            : '${(state.receivedSize / 1048576).toStringAsFixed(1)}MB / ${(state.totalSize / 1048576).toStringAsFixed(1)}MB';
        content = Column(mainAxisSize: MainAxisSize.min, children: [
          LinearProgressIndicator(value: progressValue),
          const SizedBox(height: 12),
          Text(progressText),
        ]);
        actions = [ TextButton(onPressed: () => ref.read(downloadManagerProvider).cancelDownload(), child: const Text("Cancel")) ];
        break;
      default:
        content = const Center(child: CircularProgressIndicator());
    }

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(state.taskName.isNotEmpty ? state.taskName : 'Download'),
        content: content,
        actions: actions,
      ),
    );
  }
}