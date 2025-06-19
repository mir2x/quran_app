import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:path_provider/path_provider.dart';

// Import screenutil
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/downloader/download_dialog.dart';
import '../../../../shared/downloader/download_permission_dialog.dart';
import '../../../quran/view/quran_viewer_screen.dart';
import '../../model/quran_edition.dart';
import '../providers/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Remove MediaQuery width calculation
    // final screenWidth = MediaQuery.of(context).size.width;
    // final horizontalPadding = screenWidth * 0.05; // This will be replaced by .w
    // const verticalPadding = 24.0; // This will be replaced by .h
    // const gridSpacing = 16.0; // This will be replaced by .r

    final quranEditions = ref.watch(quranEditionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          // Use screenutil for padding
          horizontal: 18.w,
          // Assuming 5% of design width (e.g., 360 * 0.05 = 18)
          vertical: 24.h,
        ),
        child: Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quranEditions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                // Remove const as values are not const
                crossAxisCount: 2,
                // Use screenutil for spacing
                crossAxisSpacing: 16.r,
                mainAxisSpacing: 16.r,
                childAspectRatio:
                    0.65, // Keep ratio as it defines the item shape
              ),
              itemBuilder: (context, index) {
                return _QuranEditionGridItem(edition: quranEditions[index]);
              },
            ),
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
      aspectRatio: 0.65, // Keep ratio

      // Removed LayoutBuilder as we'll use Expanded/Flexible for height split
      // child: LayoutBuilder(
      //   builder: (context, constraints) {
      //     final imageHeight = constraints.maxHeight * 0.8;
      //     final titleHeight = constraints.maxHeight * 0.2;
      child: Column(
        // Use Column directly
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // Ensure children fill width
        children: [
          // Replaced SizedBox with Expanded for image part (approx 80%)
          Expanded(
            flex: 4, // 4 parts out of 5 (4/5 = 80%)
            // height: imageHeight, // Remove fixed/calculated height
            child: InkWell(
              // Use screenutil for border radius
              borderRadius: BorderRadius.circular(8.r),
              onTap: () async {
                if (!edition.isDownloaded) {
                  final confirmed = await downloadPermissionDialog(
                    context,
                    "edition",
                    editionName: edition.title,
                  );
                  if (!confirmed) return;

                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => DownloadDialog(
                      id: edition.id,
                      zipUrl: edition.url,
                      sizeBytes: edition.sizeBytes,
                    ),
                  );
                  ref
                      .read(quranEditionProvider.notifier)
                      .markAsDownloaded(edition.id);
                }

                final dir = await getApplicationDocumentsDirectory();
                final editionDir = Directory('${dir.path}/${edition.id}');

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuranViewerScreen(
                        editionDir: editionDir,
                        imageWidth: edition.imageWidth,
                        imageHeight: edition.imageHeight,
                        imageExt: edition.imageExt,
                      ),
                    ),
                  );
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: double.infinity, // Takes available width
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // Use screenutil for border radius
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          // Use screenutil for shadow values
                          spreadRadius: 1.r,
                          blurRadius: 5.r,
                          offset: Offset(0, 3.r), // Scaled offset
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      // Use screenutil for border radius
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.asset(
                        edition.coverImagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (hasCheckmark)
                    Positioned(
                      // Use screenutil for vertical offset
                      top: -15.h,
                      child: Icon(
                        HugeIcons.solidRoundedLocationCheck02,
                        // Use screenutil for icon size
                        size: 36.r,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Replaced SizedBox with Expanded for title part (approx 20%)
          Expanded(
            flex: 1, // 1 part out of 5
            // height: titleHeight, // Remove fixed/calculated height
            child: Center(
              // Center the text vertically within the expanded space
              child: Text(
                edition.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  // Remove const as font size is scaled
                  // Use screenutil for font size
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
      // Removed LayoutBuilder closing
      //   },
      // ),
    );
  }
}
