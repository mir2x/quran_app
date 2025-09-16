import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../downloader/view/show_download_dialog.dart';
import '../../../downloader/viewmodel/download_providers.dart';
import '../../model/ayah.dart';
import '../../model/tafsir.dart';
import '../../viewmodel/tafsir_provider.dart';

class TafsirView extends ConsumerStatefulWidget {
  final int suraNumber;
  final int ayahNumber;

  const TafsirView({
    super.key,
    required this.suraNumber,
    required this.ayahNumber,
  });

  @override
  ConsumerState<TafsirView> createState() => _TafsirViewState();
}

class _TafsirViewState extends ConsumerState<TafsirView> {
  int? _expandedPanelIndex;

  @override
  Widget build(BuildContext context) {
    final ayahIdentifier = AyahIdentifier(sura: widget.suraNumber, ayah: widget.ayahNumber);
    final tafsirAsyncValue = ref.watch(tafsirProvider(ayahIdentifier));

    return tafsirAsyncValue.when(
      data: (tafsirData) {
        return SingleChildScrollView(
          child: ExpansionPanelList(
            expansionCallback: (index, isExpanded) => setState(() {
              _expandedPanelIndex = _expandedPanelIndex == index ? null : index;
            }),
            animationDuration: const Duration(milliseconds: 300),
            elevation: 1,
            children: tafsirData.asMap().entries.map<ExpansionPanel>((entry) {
              int index = entry.key;
              var item = entry.value;

              return ExpansionPanel(
                canTapOnHeader: true,
                backgroundColor: const Color(0xFFE6F0E6),
                isExpanded: _expandedPanelIndex == index,
                headerBuilder: (context, isExpanded) {
                  return ListTile(
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontFamily: 'SolaimanLipi',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E4D2B),
                      ),
                      textAlign: TextAlign.left,
                    ),
                  );
                },
                // --- CONDITIONAL BODY ---
                body: Container(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  alignment: Alignment.centerLeft,
                  child: item.isDownloaded
                      ? Text( // If downloaded, show the content
                    item.content ?? "তাফসীর লোড হচ্ছে...",
                    style: const TextStyle(
                      fontFamily: 'SolaimanLipi', fontSize: 15, height: 1.8, color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  )
                      : _buildDownloadButton(item, ayahIdentifier), // Otherwise, show download button
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  // --- NEW WIDGET FOR THE DOWNLOAD BUTTON ---
  Widget _buildDownloadButton(TafsirSource tafsir, AyahIdentifier ayahIdentifier) {
    final sizeInMB = (tafsir.sizeBytes / 1048576).toStringAsFixed(1);
    return Column(
      children: [
        const Text(
          "এই তাফসীরটি ডাউনলোড করা নেই।",
          style: TextStyle(fontFamily: 'SolaimanLipi', fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.download),
          label: Text("ডাউনলোড করুন ($sizeInMB MB)"),
          onPressed: () async {
            // Get the local path where the file should be saved
            final localPath = await ref.read(tafsirRepositoryProvider).getLocalTafsirPath(tafsir.id);

            // Create the specific download task
            final tafsirDownloadTask = SingleFileDownloadTask(
              id: tafsir.id,
              displayName: tafsir.title,
              fileUrl: tafsir.url,
              localPath: localPath,
            );

            // Show the unified dialog
            if (!mounted) return;
            showDownloadDialog(context);

            // Start the download and wait for the result
            final success = await ref.read(downloadManagerProvider).startDownload(tafsirDownloadTask);

            // After download, refresh the provider to reload the data
            if (success) {
              ref.invalidate(tafsirProvider(ayahIdentifier));
            }
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

void showTafsirBottomSheet(BuildContext context, String suraName, Ayah ayah) {
  showModalBottomSheet(
    context: context,

    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (BuildContext bc) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6, // Start at 60% of the screen height
        minChildSize: 0.4,     // Can be dragged down to 40%
        maxChildSize: 0.9,     // Can be dragged up to 90%
        expand: false,
        builder: (_, scrollController) {
          return Container(
            color: const Color(0xFFF0F5F0), // A light background color
            child: Column(
              children: [
                // Header for the bottom sheet
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'তাফসীর: $suraName, আয়াত ${ayah.ayah}',
                    style: const TextStyle(
                      fontFamily: 'SolaimanLipi',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                // The expandable list
                Expanded(
                  // We pass the scrollController to make the list scrollable within the sheet
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: TafsirView(
                      suraNumber: ayah.sura,
                      ayahNumber: ayah.ayah,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}