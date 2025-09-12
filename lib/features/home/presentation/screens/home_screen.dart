import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../downloader/view/show_download_dialog.dart';
import '../../../downloader/view/show_download_permission_dialog.dart';
import '../../../downloader/viewmodel/download_providers.dart';
import '../../../quran/view/quran_viewer_screen.dart';
import '../../../sura_list/view/sura_list_page.dart';
import '../../model/quran_edition.dart';
import '../providers/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quranEditions = ref.watch(quranEditionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 18.w,
          vertical: 24.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quranEditions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.r,
                mainAxisSpacing: 16.r,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (context, index) {
                return _QuranEditionGridItem(edition: quranEditions[index]);
              },
            ),
            SizedBox(height: 24.h),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SuraListPage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                side: BorderSide(
                    color: Theme.of(context).primaryColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                foregroundColor: Theme.of(context).primaryColor,
              ),
              child: Text(
                'তাফসীর',
                style: TextStyle(
                  fontFamily: 'SolaimanLipi',
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),

            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

class _QuranEditionGridItem extends ConsumerWidget {
  final QuranEdition edition;

  const _QuranEditionGridItem({required this.edition});

  bool get hasCheckmark => edition.isDownloaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AspectRatio(
      aspectRatio: 0.65,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: InkWell(
              borderRadius: BorderRadius.circular(8.r),
              onTap: () async {
                if (!edition.isDownloaded) {
                  // This block for starting a download is correct. No changes needed here.
                  final confirmed = await showDownloadPermissionDialog(
                    context,
                    assetName: edition.title,
                    sizeInfo: "(${(edition.sizeBytes / 1048576).toStringAsFixed(1)} MB)",
                  );
                  if (!confirmed || !context.mounted) return;

                  final mushafDownloadTask = ZipDownloadTask(
                    id: edition.id,
                    displayName: edition.title,
                    zipUrl: edition.url,
                  );

                  showDownloadDialog(context); // Using the new unified dialog
                  ref.read(downloadManagerProvider).startDownload(mushafDownloadTask);
                } else {
                  // --- This block for navigating is now fixed ---
                  // 1. Get the local directory path for the downloaded edition.
                  // This requires an `async` call.
                  final dirPath = await getLocalPath(edition.id); // From your fileChecker.dart
                  final editionDirectory = Directory(dirPath);

                  // 2. A safety check to ensure the files actually exist before navigating.
                  if (await editionDirectory.exists() && context.mounted) {
                    // 3. Navigate with all the correct parameters from the `edition` object.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuranViewerScreen(
                          editionDir: editionDirectory,
                          imageWidth: edition.imageWidth,
                          imageHeight: edition.imageHeight,
                          imageExt: edition.imageExt,
                        ),
                      ),
                    );
                  } else if (context.mounted) {
                    // Show an error if files are missing, prompting a re-download.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error: Mushaf files not found. Please try downloading again.')),
                    );
                  }
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1.r,
                          blurRadius: 5.r,
                          offset: Offset(0, 3.r),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.asset(
                        edition.coverImagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (hasCheckmark)
                    Positioned(
                      top: -15.h,
                      child: Icon(
                        HugeIcons.solidRoundedLocationCheck02,
                        size: 36.r,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                edition.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
                  fontFamily: 'SolaimanLipi',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}