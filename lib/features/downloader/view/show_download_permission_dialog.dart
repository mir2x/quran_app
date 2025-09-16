import 'package:flutter/material.dart';

String _toBanglaNumber(String input) {
  const en = ['0','1','2','3','4','5','6','7','8','9','MB','KB','GB'];
  const bn = ['০','১','২','৩','৪','৫','৬','৭','৮','৯','এমবি','কেবি','জিবি'];

  String output = input;
  for (int i = 0; i < en.length; i++) {
    output = output.replaceAll(en[i], bn[i]);
  }
  return output;
}

String cleanAssetName(String assetName) {
  return assetName.replaceAll(RegExp(r'[\n\r]+'), ' ').trim();
}

Future<bool> showDownloadPermissionDialog(
    BuildContext context, {
      required String assetName,
      String? sizeInfo,
    }) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('ডাউনলোড প্রয়োজন'),
      content: Text(
        '${cleanAssetName(assetName)} এখনো ডাউনলোড করা হয়নি। এখনই ডাউনলোড করতে চান? ${sizeInfo != null ? _toBanglaNumber(sizeInfo) : ""}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('বাতিল'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('এখনই ডাউনলোড করুন'),
        ),
      ],
    ),
  ) ?? false;
}
