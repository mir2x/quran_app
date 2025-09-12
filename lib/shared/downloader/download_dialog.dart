// import 'package:flutter/material.dart';
// import '../../core/services/downloader.dart';
//
// class DownloadDialog extends StatefulWidget {
//   final String id;
//   final String zipUrl;
//   final int sizeBytes;
//
//   const DownloadDialog({super.key, required this.id, required this.zipUrl, required this.sizeBytes});
//
//   @override
//   State<DownloadDialog> createState() => _DownloadDialogState();
// }
//
// class _DownloadDialogState extends State<DownloadDialog> {
//   int received = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _startDownload();
//   }
//
//   Future<void> _startDownload() async {
//     await downloadAndExtract(widget.id, widget.zipUrl, (r, _) {
//       setState(() => received = r);
//     });
//     if (mounted) Navigator.pop(context);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final totalMB = widget.sizeBytes / (1024 * 1024);
//     final downloadedMB = received / (1024 * 1024);
//
//     return AlertDialog(
//       title: const Center(
//         child: Text('ডাউনলোড হচ্ছে', textAlign: TextAlign.center),
//       ),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           LinearProgressIndicator(value: received / widget.sizeBytes),
//           const SizedBox(height: 12),
//           Text(
//             '${downloadedMB.toStringAsFixed(1)}MB / ${totalMB.toStringAsFixed(1)}MB',
//           ),
//         ],
//       ),
//     );
//   }
// }
