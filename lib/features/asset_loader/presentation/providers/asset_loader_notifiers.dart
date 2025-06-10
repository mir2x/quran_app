import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'asset_loader_state.dart';
import 'folder_downloader_provider.dart';

class AssetLoaderNotifiers extends StateNotifier<AssetLoaderState> {
  final FolderDownloader folderDownloader;
  final String assetPath;
  AssetLoaderNotifiers({
    required this.folderDownloader,
    required this.assetPath,
  }) : super(const AssetLoaderState(progress: 0, status: "Checking files...", done: false));

  Future<void> loadAssets(List<String> imageFiles, List<String> jsonFiles) async {
    try {
      final imageReady = await folderDownloader.allFilesExist("image", assetPath, imageFiles);
      final jsonReady = await folderDownloader.allFilesExist("image_json", assetPath, jsonFiles);
      if (imageReady && jsonReady) {
        state = state.copyWith(progress: 1, status: "Done", done: true);
        return;
      }

      int steps = 0, totalSteps = 2;
      if (!imageReady) {
        state = state.copyWith(status: "Downloading image files...");
        await folderDownloader.downloadAllFiles(
          bucket: "assets",
          type: "image",
          folder: assetPath,
          files: imageFiles,
          onProgress: (p, done, total) {
            state = state.copyWith(
              progress: (steps + p) / totalSteps,
              status: "Downloading image files ($done/$total)...",
            );
          },
        );
      }
      steps++;
      if (!jsonReady) {
        state = state.copyWith(status: "Downloading json files...");
        await folderDownloader.downloadAllFiles(
          bucket: "assets",
          type: "image_json",
          folder: assetPath,
          files: jsonFiles,
          onProgress: (p, done, total) {
            state = state.copyWith(
              progress: (steps + p) / totalSteps,
              status: "Downloading json files ($done/$total)...",
            );
          },
        );
      }
      state = state.copyWith(progress: 1, status: "Done", done: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
