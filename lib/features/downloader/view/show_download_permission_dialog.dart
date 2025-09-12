import 'package:flutter/material.dart';

Future<bool> showDownloadPermissionDialog(
    BuildContext context, {
      required String assetName, // e.g., "15-Line Mushaf" or "Tafsir Ibn Kathir"
      String? sizeInfo, // e.g., "(approx. 50 MB)"
    }) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Download Required'),
      content: Text('Files for "$assetName" are not downloaded. Would you like to download now? ${sizeInfo ?? ""}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Download Now')),
      ],
    ),
  ) ?? false;
}