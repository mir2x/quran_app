import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/home/view/widget/dowloand_dailog.dart';

import '../../quran/view/quran_viewer_screen.dart';
import '../model/download_state.dart';
import '../viewmodel/edition_viewmodel.dart';


class EditionSelectionScreen extends ConsumerWidget {
  const EditionSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogue = ref.watch(catalogueProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Edition')),
      body: ListView.separated(
        itemCount: catalogue.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final edition = catalogue[i];
          final dlState = ref.watch(downloadStateProvider(edition));
          return ListTile(
            title: Text(edition.name),
            subtitle: switch (dlState) {
              NotDownloaded()              => const Text('Not downloaded'),
              Downloading(:final received, :final total) => Text(
                  '${(received / (1024 * 1024)).toStringAsFixed(1)} MB / '
                      '${(total    / (1024 * 1024)).toStringAsFixed(1)} MB'),
              Downloaded()                 => const Text('Ready'),
              Failed(:final msg)           => Text('Error: $msg',
                  style: const TextStyle(color: Colors.red)),
            },
            trailing: _Trailing(dlState),
            onTap: () async {
              if (dlState is NotDownloaded) {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => DownloadDialog(edition: edition),
                );
                if (ok == true) {
                  ref.read(downloadStateProvider(edition).notifier)
                      .startDownload();
                }
              } else if (dlState is Downloaded) {
                // Already local → open viewer
                final storage = await ref.read(storageProvider.future);
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuranViewerScreen(
                        editionDir: storage.dirFor(edition.id),
                        imageWidth: edition.imageWidth,
                        imageHeight: edition.imageHeight,
                      ),
                    ),
                  );
                }
              }
            },
          );
        },
      ),
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing(this.state);
  final DownloadState state;

  @override
  Widget build(BuildContext context) => switch (state) {
    NotDownloaded()  => const Icon(Icons.cloud_download),
    Downloaded() => const Icon(Icons.book),
    Failed() => const Icon(Icons.error, color: Colors.red),
    Downloading(:final percent) =>
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(value: percent),
        ),
  };
}
