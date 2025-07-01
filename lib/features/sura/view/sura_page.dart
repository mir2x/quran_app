// lib/features/sura/ui/pages/surah_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/sura/view/widgets/auto_scroll_controller.dart';
import 'package:quran_app/features/sura/view/widgets/ayah_card.dart';
import 'package:quran_app/features/sura/view/widgets/details_bottom_sheet.dart';
import 'package:quran_app/features/sura/view/widgets/translation_selection_dialog.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../core/services/auto_scroll_service.dart';
import '../viewmodel/sura_viewmodel.dart';
// ... other imports

class SurahPage extends ConsumerStatefulWidget {
  // 1. Add suraNumber as a required final field
  final int suraNumber;

  // 2. Update the constructor
  const SurahPage({
    super.key,
    required this.suraNumber,
  });

  @override
  ConsumerState<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends ConsumerState<SurahPage> {
  late final AutoScrollService _autoScrollService;

  @override
  void initState() {
    super.initState();
    _autoScrollService = AutoScrollService(
      itemScrollController: ItemScrollController(),
      itemPositionsListener: ItemPositionsListener.create(),
      ref: ref,
    );
  }

  @override
  void dispose() {
    _autoScrollService.stopAutoScroll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suraAsyncValue = ref.watch(suraProvider(widget.suraNumber));
    final controllerVisible = ref.watch(autoScrollControllerVisibleProvider);
    final suraName = "সূরা ${widget.suraNumber}";

    return Scaffold(
      appBar: _buildAppBar(context, suraName),
      body: suraAsyncValue.when(
        data: (ayahs) {
          // Pass the loaded ayahs count to the service
          _autoScrollService.totalItemCount = ayahs.length;

          return ScrollablePositionedList.builder(
            itemScrollController: _autoScrollService.itemScrollController,
            itemPositionsListener: _autoScrollService.itemPositionsListener,
            itemCount: ayahs.length,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemBuilder: (context, index) {
              return AyahCard(
                ayah: ayahs[index],
                suraName: suraName, // Pass the sura name
                selectedTranslators: ref.watch(selectedTranslatorsProvider),
                showTranslations: ref.watch(showTranslationsProvider),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load Sura ${widget.suraNumber}:\n$error')),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, ref),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: controllerVisible
          ? AutoScrollController(autoScrollService: _autoScrollService)
          : null,
    );
  }

  // Update AppBar to accept a dynamic title
  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'SolaimanLipi', color: Colors.white),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context, WidgetRef ref) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green.shade700,
      unselectedItemColor: Colors.grey.shade600,
      selectedLabelStyle: const TextStyle(fontFamily: 'SolaimanLipi'),
      unselectedLabelStyle: const TextStyle(fontFamily: 'SolaimanLipi'),
      onTap: (index) => _onNavBarTapped(index, context, ref),
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'অনুবাদ'),
        BottomNavigationBarItem(icon: Icon(Icons.text_fields), label: 'শব্দে শব্দে'),
        BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill_outlined), label: 'অডিও শুনুন'),
        BottomNavigationBarItem(icon: Icon(Icons.swipe_outlined), label: 'অটো স্ক্রল'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_on), label: 'বিস্তারিত'),
      ],
    );
  }

  void _onNavBarTapped(int index, BuildContext context, WidgetRef ref) {
    switch (index) {
      case 0: // অনুবাদ
        showDialog(
          context: context,
          builder: (context) => const TranslatorSelectionDialog(),
        );
        break;
      case 3: // অটো স্ক্রল
        ref.read(autoScrollControllerVisibleProvider.notifier).state = true;
        _autoScrollService.startAutoScroll();
        break;
      case 4: // বিস্তারিত
        showDetailsBottomSheet(context);
        break;
      default:
        print('Bottom nav item tapped: $index');
    }
  }
}