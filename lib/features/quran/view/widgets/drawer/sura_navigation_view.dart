import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../viewmodel/ayah_highlight_viewmodel.dart';

// State provider for the selected Surah (defaults to 1)
final selectedNavigationSurahProvider = StateProvider<int>((_) => 1);
// State provider for the selected Ayah (can be null)
final selectedNavigationAyahProvider = StateProvider<int?>((_) => null);


class SurahNavigationView extends ConsumerStatefulWidget {
  const SurahNavigationView({super.key});

  @override
  ConsumerState<SurahNavigationView> createState() =>
      _SurahNavigationViewState();
}

class _SurahNavigationViewState extends ConsumerState<SurahNavigationView> {
  // --- Controllers for BOTH lists ---
  final ItemScrollController _surahScrollController = ItemScrollController();
  final ItemScrollController _ayahScrollController = ItemScrollController();

  bool _isInitialStateSet = false;

  String toBengaliNumber(int number) {
    const bengaliNumbers = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    String numberStr = number.toString();
    String bengaliStr = '';
    for (int i = 0; i < numberStr.length; i++) {
      int digit = int.parse(numberStr[i]);
      bengaliStr += bengaliNumbers[digit];
    }
    return bengaliStr;
  }

  @override
  Widget build(BuildContext context) {
    final allBoxesAsync = ref.watch(allBoxesProvider);
    if (allBoxesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (allBoxesAsync.hasError) {
      return Center(child: Text('Error loading Surah/Ayah data', style: TextStyle(fontSize: 14.sp)));
    }

    final suraPageMapping = ref.watch(suraPageMappingProvider);
    final selectedAyah = ref.watch(selectedAyahProvider);

    // --- SMART STATE RETENTION LOGIC ---
    if (!_isInitialStateSet && suraPageMapping.isNotEmpty) {
      // Use the highlighted Ayah if available, otherwise find Surah from current page.
      int currentSurah = selectedAyah?.suraNumber ?? 1;
      int? currentAyah = selectedAyah?.ayahNumber;

      if (currentAyah == null) {
        final currentPage = ref.read(currentPageProvider) + 1;
        for (int i = 1; i <= 114; i++) {
          if (suraPageMapping.containsKey(i) && suraPageMapping[i]! <= currentPage) {
            currentSurah = i;
          } else {
            break;
          }
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedNavigationSurahProvider.notifier).state = currentSurah;
          ref.read(selectedNavigationAyahProvider.notifier).state = currentAyah;

          _surahScrollController.jumpTo(index: currentSurah - 1);

          if (currentAyah != null) {
            _ayahScrollController.jumpTo(index: currentAyah - 1);
          }
        }
      });
      _isInitialStateSet = true;
    }
    // --- END OF SMART LOGIC ---

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 3, child: _buildSurahList(ref)),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(flex: 2, child: _buildRightPane(ref)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('সুরা', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp, fontFamily: 'SolaimanLipi')),
          ),
          Expanded(
            flex: 2,
            child: Text('আয়াত', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp, fontFamily: 'SolaimanLipi')),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList(WidgetRef ref) {
    final selectedSurah = ref.watch(selectedNavigationSurahProvider);
    final suraNames = ref.watch(suraNamesProvider);
    final selectedAyah = ref.watch(selectedAyahProvider);

    return ScrollablePositionedList.separated(
      itemScrollController: _surahScrollController,
      padding: EdgeInsets.zero,
      itemCount: 114,
      separatorBuilder: (context, index) => Divider(height: 1.h, color: Colors.grey.shade300),
      itemBuilder: (context, index) {
        final suraNumber = index + 1;
        final isSelected = suraNumber == selectedSurah;

        return ListTile(
          tileColor: isSelected ? Theme.of(context).primaryColor : null,
          title: Text(
            '${toBengaliNumber(suraNumber)}. ${suraNames[index]}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
          onTap: () {
            ref.read(selectedNavigationSurahProvider.notifier).state = suraNumber;
            // When a new surah is tapped, update the selected ayah to reflect the current reading state
            ref.read(selectedNavigationAyahProvider.notifier).state = selectedAyah?.ayahNumber;
          },
        );
      },
    );
  }

  Widget _buildRightPane(WidgetRef ref) {
    final selectedSurah = ref.watch(selectedNavigationSurahProvider);
    final selectedAyah = ref.watch(selectedNavigationAyahProvider);
    final ayahCounts = ref.watch(ayahCountsProvider);
    final ayahPageMapping = ref.watch(ayahPageMappingProvider);

    final totalAyahs = ayahCounts[selectedSurah - 1];

    // Auto-scroll the Ayah list when the selected Surah changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _ayahScrollController.isAttached) {
        final currentAyah = ref.read(selectedAyahProvider)?.ayahNumber;
        if (currentAyah != null) {
          _ayahScrollController.jumpTo(index: currentAyah - 1);
        }
      }
    });

    return ScrollablePositionedList.separated(
      itemScrollController: _ayahScrollController,
      padding: EdgeInsets.zero,
      separatorBuilder: (context, index) => Divider(height: 1.h, color: Colors.grey.shade300),
      itemCount: totalAyahs,
      itemBuilder: (context, index) {
        final ayahNumber = index + 1;
        final isSelected = selectedSurah == selectedSurah && ayahNumber == selectedAyah;

        return ListTile(
          tileColor: isSelected ? Theme.of(context).primaryColor : null,
          title: Center(
            child: Text(
              toBengaliNumber(ayahNumber),
              style: TextStyle(
                fontSize: 14.sp,
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          onTap: () {
            final targetPage = ayahPageMapping[(selectedSurah, ayahNumber)];
            if (targetPage != null) {
              ref.read(navigateToPageCommandProvider.notifier).state = targetPage;
              ref.read(selectedAyahProvider.notifier).selectByNavigation(selectedSurah, ayahNumber);
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Page data not found for this Ayah')),
              );
            }
          },
        );
      },
    );
  }
}