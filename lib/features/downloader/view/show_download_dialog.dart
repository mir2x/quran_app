import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/download_state.dart';
import '../viewmodel/download_providers.dart';

String _toBanglaNumber(String input) {
  const en = ['0','1','2','3','4','5','6','7','8','9','MB','KB','GB'];
  const bn = ['০','১','২','৩','৪','৫','৬','৭','৮','৯','এমবি','কেবি','জিবি'];

  String output = input;
  for (int i = 0; i < en.length; i++) {
    output = output.replaceAll(en[i], bn[i]);
  }
  return output;
}


void showDownloadDialog(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  final status = container.read(downloadStateProvider).status;
  if (status == DownloadStatus.completed ||
      status == DownloadStatus.idle ||
      status == DownloadStatus.error) {
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
      if (next.status == DownloadStatus.completed ||
          next.status == DownloadStatus.cancelled) {
        if (Navigator.canPop(context)) Navigator.of(context).pop();
      }
    });

    Widget content;
    List<Widget> actions = [];

    switch (state.status) {
      case DownloadStatus.error:
        content = Text(state.errorMessage ?? "অজানা একটি সমস্যা ঘটেছে।");
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("ঠিক আছে"),
          )
        ];
        break;
      case DownloadStatus.extracting:
        content = const Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("ফাইলগুলো এক্সট্র্যাক্ট করা হচ্ছে..."),
          ],
        );
        break;
      case DownloadStatus.preparing:
        content = const Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("ডাউনলোড প্রস্তুত করা হচ্ছে..."),
          ],
        );
        break;
      case DownloadStatus.downloading:
        final bool isMultiFile = state.totalItems > 0;
        final progressValue = isMultiFile
            ? (state.totalItems > 0
            ? state.completedItems / state.totalItems
            : null)
            : (state.totalSize > 0
            ? state.receivedSize / state.totalSize
            : null);

        final rawProgressText = isMultiFile
            ? 'ডাউনলোড হয়েছে ${state.completedItems} / ${state.totalItems}'
            : '${(state.receivedSize / 1048576).toStringAsFixed(1)} এমবি / ${(state.totalSize / 1048576).toStringAsFixed(1)} এমবি';

        final progressText = _toBanglaNumber(rawProgressText);

        content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: progressValue),
            const SizedBox(height: 12),
            Text(progressText),
          ],
        );
        actions = [
          TextButton(
            onPressed: () =>
                ref.read(downloadManagerProvider).cancelDownload(),
            child: const Text("বাতিল"),
          )
        ];
        break;
      default:
        content = const Center(child: CircularProgressIndicator());
    }

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(state.taskName.isNotEmpty ? state.taskName : 'ডাউনলোড'),
        content: content,
        actions: actions,
      ),
    );
  }
}
