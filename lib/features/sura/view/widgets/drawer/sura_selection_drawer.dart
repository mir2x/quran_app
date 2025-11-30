import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:quran_app/features/quran/viewmodel/ayah_highlight_viewmodel.dart';
import 'package:quran_app/features/sura/viewmodel/sura_viewmodel.dart';
import 'package:quran_app/features/sura/view/sura_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

final selectedDrawerSurahProvider = StateProvider<int>((ref) => 1);
final selectedDrawerAyahProvider = StateProvider<int?>((ref) => null);

class SuraSelectionDrawer extends ConsumerStatefulWidget {
  final int currentSuraNumber;
  const SuraSelectionDrawer({super.key, required this.currentSuraNumber});

  @override
  ConsumerState<SuraSelectionDrawer> createState() =>
      _SuraSelectionDrawerState();
}

class _SuraSelectionDrawerState extends ConsumerState<SuraSelectionDrawer> {
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
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedDrawerSurahProvider.notifier).state =
          widget.currentSuraNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialStateSet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _surahScrollController.isAttached) {
          _surahScrollController.jumpTo(index: widget.currentSuraNumber - 1);
        }
      });
      _isInitialStateSet = true;
    }

    final media = MediaQuery.of(context);
    final double topInset = kToolbarHeight + media.padding.top;
    final double bottomInset = media.padding.bottom;

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
        child: SizedBox(
          width: 280.w,
          child: Material(
            elevation: 16,
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _buildSurahList(ref)),
                      const VerticalDivider(width: 1, thickness: 1),
                      Expanded(flex: 2, child: _buildAyahList(ref)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
            child: Text(
              'সুরা',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                fontFamily: 'SolaimanLipi',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'আয়াত',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                fontFamily: 'SolaimanLipi',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList(WidgetRef ref) {
    final selectedSurah = ref.watch(selectedDrawerSurahProvider);
    final suraNames = ref.watch(suraNamesProvider);

    return ScrollablePositionedList.separated(
      itemScrollController: _surahScrollController,
      padding: EdgeInsets.zero,
      itemCount: 114,
      separatorBuilder: (context, index) =>
          Divider(height: 1.h, color: Colors.grey.shade300),
      itemBuilder: (context, index) {
        final suraNumber = index + 1;
        final isSelected = suraNumber == selectedSurah;

        return ListTile(
          tileColor: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : null,
          title: Text(
            '${toBengaliNumber(suraNumber)}. ${suraNames[index]}',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color:
                  isSelected ? Theme.of(context).primaryColor : Colors.black87,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
          onTap: () {
            ref.read(selectedDrawerSurahProvider.notifier).state = suraNumber;
          },
        );
      },
    );
  }

  Widget _buildAyahList(WidgetRef ref) {
    final selectedSurah = ref.watch(selectedDrawerSurahProvider);
    final ayahCounts = ref.watch(ayahCountsProvider);

    if (selectedSurah < 1 || selectedSurah > 114) return const SizedBox();

    final totalAyahs = ayahCounts[selectedSurah - 1];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _ayahScrollController.isAttached) {}
    });

    return ScrollablePositionedList.separated(
      itemScrollController: _ayahScrollController,
      padding: EdgeInsets.zero,
      separatorBuilder: (context, index) =>
          Divider(height: 1.h, color: Colors.grey.shade300),
      itemCount: totalAyahs,
      itemBuilder: (context, index) {
        final ayahNumber = index + 1;

        return ListTile(
          title: Center(
            child: Text(
              toBengaliNumber(ayahNumber),
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black87,
              ),
            ),
          ),
          onTap: () {
            _onAyahSelected(context, selectedSurah, ayahNumber);
          },
        );
      },
    );
  }

  void _onAyahSelected(
      BuildContext context, int suraNumber, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_read_sura', suraNumber);
    await prefs.setInt('last_read_ayah_index', ayahNumber - 1);

    if (!mounted) return;

    if (suraNumber == widget.currentSuraNumber) {
      ref.read(suraScrollCommandProvider.notifier).state = ScrollCommand(
        suraNumber: suraNumber,
        scrollIndex: ayahNumber - 1,
      );
      Navigator.pop(context);
    } else {
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SurahPage(
            suraNumber: suraNumber,
            initialScrollIndex: ayahNumber - 1,
          ),
        ),
      );
    }
  }
}
