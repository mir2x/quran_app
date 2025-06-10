import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/asset_loader/presentation/providers/asset_loader_notifiers.dart';
import 'package:quran_app/features/asset_loader/presentation/providers/asset_loader_state.dart';

import 'folder_downloader_provider.dart';

final assetLoaderProvider = StateNotifierProvider.autoDispose
    .family<AssetLoaderNotifiers, AssetLoaderState, String>(
      (ref, assetPath) => AssetLoaderNotifiers(
    folderDownloader: ref.read(folderDownloaderProvider),
    assetPath: assetPath,
  ),
);