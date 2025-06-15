import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../shared/downloader/download_dialog.dart';
import '../../../../shared/downloader/download_permission_dialog.dart';
import '../../../quran/view/quran_viewer_screen.dart';
import '../../model/quran_edition.dart';
import '../providers/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;
    const verticalPadding = 24.0;
    const gridSpacing = 16.0;

    final quranEditions = ref.watch(quranEditionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quranEditions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: gridSpacing,
                mainAxisSpacing: gridSpacing,
                childAspectRatio: 0.65,
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
      aspectRatio: 0.65,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageHeight = constraints.maxHeight * 0.8;
          final titleHeight = constraints.maxHeight * 0.2;

          return Column(
            children: [
              SizedBox(
                height: imageHeight,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8.0),
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
                      ref.read(quranEditionProvider.notifier).markAsDownloaded(edition.id);
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
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.asset(
                            edition.coverImagePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (hasCheckmark)
                        Positioned(
                          top: -15,
                          child: Icon(HugeIcons.solidRoundedLocationCheck02, size: 36)
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: titleHeight,
                child: Center(
                  child: Text(
                    edition.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

