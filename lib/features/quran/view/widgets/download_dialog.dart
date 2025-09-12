// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../viewmodel/download_providers.dart';
//
// void showDownloadDialog(BuildContext context) {
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (BuildContext dialogContext) {
//       return PopScope(
//         canPop: false,
//         child: Consumer(
//           builder: (context, ref, _) {
//             final progress = ref.watch(downloadProgressProvider);
//             final textStyle = Theme.of(context).textTheme.titleMedium;
//
//             if (progress.error != null) {
//               return AlertDialog(
//                 title: const Text('Download Error'),
//                 content: Text(progress.error!, style: textStyle),
//                 actions: [
//                   TextButton(
//                     onPressed: () {
//                       ref.read(downloadProgressProvider.notifier).reset();
//                       Navigator.of(dialogContext).pop();
//                     },
//                     child: const Text('OK'),
//                   ),
//                 ],
//               );
//             }
//
//             final bool isDownloading = progress.totalCount > 0;
//             final String progressText = isDownloading
//                 ? 'Downloading...\n${progress.downloadedCount} / ${progress.totalCount}'
//                 : 'Preparing audio...';
//
//             return AlertDialog(
//               content: Row(
//                 children: [
//                   CircularProgressIndicator(value: isDownloading ? progress.percentage : null),
//                   SizedBox(width: 20),
//                   Text(progressText, style: textStyle),
//                 ],
//               ),
//             );
//           },
//         ),
//       );
//     },
//   );
// }