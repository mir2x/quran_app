import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/asset_loader/presentation/providers/asset_loader_provider.dart';

import '../../../quran_old/presentation/screens/quran_screen.dart';


class AssetLoaderDialog extends ConsumerStatefulWidget {
  final String assetPath;
  final int imageWidth;
  final int imageHeight;
  final List<String> imageFiles;
  final List<String> jsonFiles;

  const AssetLoaderDialog({
    super.key,
    required this.assetPath,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageFiles,
    required this.jsonFiles,
  });

  @override
  ConsumerState<AssetLoaderDialog> createState() => _AssetLoaderDialogState();
}

class _AssetLoaderDialogState extends ConsumerState<AssetLoaderDialog> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(assetLoaderProvider(widget.assetPath).notifier)
          .loadAssets(widget.imageFiles, widget.jsonFiles);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assetLoaderProvider(widget.assetPath));

    // Success: dismiss dialog and push QuranScreen
    if (state.done) {
      Future.microtask(() {
        Navigator.of(context).pop(); // Close the dialog
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuranScreen(
              assetPath: widget.assetPath,
              imageWidth: widget.imageWidth,
              imageHeight: widget.imageHeight,
              imageFiles: widget.imageFiles,
            ),
          ),
        );
      });
    }

    // Error state
    if (state.error != null) {
      return Center(
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 56),
                const SizedBox(height: 16),
                Text('Error: ${state.error}', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  child: const Text('Retry'),
                  onPressed: () => ref
                      .read(assetLoaderProvider(widget.assetPath).notifier)
                      .loadAssets(widget.imageFiles, widget.jsonFiles),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Loading state
    return Center(
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: state.progress),
              const SizedBox(height: 20),
              Text(state.status, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text("${(state.progress * 100).toStringAsFixed(0)}%"),
            ],
          ),
        ),
      ),
    );
  }
}
