import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../downloader/view/show_download_dialog.dart';
import '../../../downloader/view/show_download_permission_dialog.dart';
import '../../../downloader/viewmodel/download_providers.dart';
import '../../../quran/view/quran_viewer_screen.dart';
import '../../../sura/view/sura_page.dart';
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
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 24.h),
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
                childAspectRatio: 0.5,
              ),
              itemBuilder: (context, index) {
                return _QuranEditionGridItem(edition: quranEditions[index]);
              },
            ),
            SizedBox(height: 24.h),
            OutlinedButton(
              // The onPressed function is now async to wait for SharedPreferences
              onPressed: () async {
                // 1. Get an instance of SharedPreferences
                final prefs = await SharedPreferences.getInstance();

                // 2. Read the stored sura number and ayah index
                final int? lastSura = prefs.getInt('last_read_sura');
                final int? lastAyahIndex = prefs.getInt('last_read_ayah_index');

                // 3. IMPORTANT: Check if the widget is still in the widget tree before navigating
                if (!context.mounted) return;

                // 4. Decide where to navigate
                if (lastSura != null && lastAyahIndex != null) {
                  // If a last read position exists, navigate directly to the SurahPage
                  debugPrint('Found last read: Sura $lastSura, Ayah $lastAyahIndex. Navigating to SurahPage.');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurahPage(
                        suraNumber: lastSura,
                        initialScrollIndex: lastAyahIndex,
                      ),
                      // Optional: Add settings name for popUntil logic if you use it
                      settings: RouteSettings(name: '/surah/$lastSura'),
                    ),
                  );
                } else {
                  // If no position is saved, navigate to the Sura List Page as before
                  debugPrint('No last read found. Navigating to SuraListPage.');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SuraListPage()),
                  );
                }
              },
              // --- All the styling below remains exactly the same ---
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                side: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 1.5,
                ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 4,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.r),
            onTap: () async {
              // Your onTap logic is correct and does not need to change.
              if (!edition.isDownloaded) {
                final confirmed = await showDownloadPermissionDialog(
                  context,
                  assetName: edition.title,
                  sizeInfo:
                      "(${(edition.sizeBytes / 1048576).toStringAsFixed(1)} MB)",
                );
                if (!confirmed || !context.mounted) return;

                final mushafDownloadTask = ZipDownloadTask(
                  id: edition.id,
                  displayName: edition.title,
                  zipUrl: edition.url,
                );

                showDownloadDialog(context);
                ref
                    .read(downloadManagerProvider)
                    .startDownload(mushafDownloadTask);
              } else {
                final dirPath = await getLocalPath(edition.id);
                final editionDirectory = Directory(dirPath);
                if (await editionDirectory.exists() && context.mounted) {
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Error: Mushaf files not found. Please try downloading again.',
                      ),
                    ),
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
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    // --- THIS IS THE CORRECTED BOX SHADOW ---
                    boxShadow: [
                      // Shadow 1: The subtle, darker "lift" shadow at the bottom.
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        // Slightly darker but still soft
                        spreadRadius: 1.r,
                        blurRadius: 4.r,
                        // Less blur for a more defined lift
                        offset: Offset(0, 4.r), // Pushes the shadow down
                      ),
                      // Shadow 2: The wide, soft "glow" shadow for the sides.
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        // Very transparent
                        spreadRadius: 2.r,
                        // A slight spread to push it out
                        blurRadius: 12.r,
                        // Very blurry to create the soft glow
                        offset: Offset(
                          0,
                          0,
                        ), // Centered, so it spreads evenly on all sides
                      ),
                    ],
                    // --- END OF CORRECTION ---
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
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
        // The text part remains unchanged.
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
    );
  }
}
