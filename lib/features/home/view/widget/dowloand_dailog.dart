import 'package:flutter/material.dart';

import '../../model/edition.dart';


class DownloadDialog extends StatelessWidget {
  const DownloadDialog({super.key, required this.edition});
  final QuranEdition edition;

  @override
  Widget build(BuildContext context) {
    final mb = (edition.sizeBytes / (1024 * 1024)).toStringAsFixed(1);
    return AlertDialog(
      title: Text('Download "${edition.name}"?'),
      content: Text('Size: $mb MB\nThe files will be stored on your device.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Download'),
        ),
      ],
    );
  }
}
