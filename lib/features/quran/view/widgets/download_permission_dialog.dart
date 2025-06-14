import 'package:flutter/material.dart';

Future<bool> downloadPermissionDialog(
    BuildContext context, String reciterName) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      title: Text('Download Required'),
      content: Text(
          'Audio files for "$reciterName" are not downloaded. Would you like to download now?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Download Now'),
        ),
      ],
    ),
  ) ??
      false;
}
