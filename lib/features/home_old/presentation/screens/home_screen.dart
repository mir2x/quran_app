import 'package:flutter/material.dart';

import '../../../asset_loader/presentation/screens/asset_loader_dialog.dart';
import '../../data/data_sources/quran_edition_data.dart';
import '../../domain/entities/quran_edition.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;
    const verticalPadding = 24.0;
    const gridSpacing = 16.0;

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
              itemCount: quranEditionData.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: gridSpacing,
                mainAxisSpacing: gridSpacing,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (context, index) {
                return _QuranEditionGridItem(edition: quranEditionData[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuranEditionGridItem extends StatelessWidget {
  final QuranEdition edition;

  const _QuranEditionGridItem({required this.edition});

  @override
  Widget build(BuildContext context) {
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
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => AssetLoaderDialog(
                        assetPath: edition.assetPath,
                        imageWidth: edition.imageWidth,
                        imageHeight: edition.imageHeight,
                        imageFiles: edition.imageFiles,
                        jsonFiles: edition.jsonFiles,
                      ),
                    );
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
                      if (edition.hasCheckmark)
                        Positioned(
                          top: -20,
                          child: Image.asset(
                            'assets/checkmark_overlay.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
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
