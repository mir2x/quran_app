import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/sura/view/widgets/quran_page_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../model/tilawat_models.dart';
import '../../viewmodel/tilawat_providers.dart';

class TilawatPage extends ConsumerWidget {
  final int initialSuraNumber;
  final int initialAyahNumber;

  const TilawatPage({
    super.key,
    required this.initialSuraNumber,
    required this.initialAyahNumber,
  });

  int _findInitialPageIndex(List<QuranPage> surahPages) {
    for (int i = 0; i < surahPages.length; i++) {
      final page = surahPages[i];
      for (var content in page.content) {
        if (content.ayahs.any((ayah) => ayah.ayahNumber == initialAyahNumber)) {
          return i;
        }
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagesAsync = ref.watch(quranPagesProvider(initialSuraNumber));
    final ItemScrollController itemScrollController = ItemScrollController();

    return Scaffold(
      appBar: AppBar(
        title: pagesAsync.when(
          data: (pages) => Text(
            pages.isNotEmpty
                ? pages.first.content.first.suraNameBengali
                : "তিলাওয়াত মোড",
            style: const TextStyle(fontFamily: 'SolaimanLipi'),
          ),
          loading: () => const Text(''),
          error: (_, __) => const Text(''),
        ),
        backgroundColor: Colors.teal.shade800,
      ),
      body: pagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('পৃষ্ঠা লোড করা যায়নি:\n$err')),
        data: (surahPages) {
          if (surahPages.isEmpty) {
            return const Center(child: Text('কোন পৃষ্ঠা পাওয়া যায়নি।'));
          }

          final initialIndex = _findInitialPageIndex(surahPages);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (itemScrollController.isAttached) {
              itemScrollController.jumpTo(
                index: initialIndex,
                alignment: 0,
              );
            }
          });

          return ScrollablePositionedList.builder(
            itemScrollController: itemScrollController,
            itemCount: surahPages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: QuranPageWidget(page: surahPages[index]),
              );
            },
          );
        },
      ),
    );
  }
}
