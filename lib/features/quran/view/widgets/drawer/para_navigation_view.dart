import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../viewmodel/ayah_highlight_viewmodel.dart';

// The providers and the StatefulWidget structure remain the same.
final selectedNavigationParaProvider = StateProvider<int>((_) => 1);
final selectedNavigationPageProvider = StateProvider<int?>((_) => null);

class ParaNavigationView extends ConsumerStatefulWidget {
  const ParaNavigationView({super.key});

  @override
  ConsumerState<ParaNavigationView> createState() => _ParaNavigationViewState();
}

class _ParaNavigationViewState extends ConsumerState<ParaNavigationView> {
  // All state and initial logic remains the same.
  final ItemScrollController _paraScrollController = ItemScrollController();
  final ItemScrollController _pageScrollController = ItemScrollController();
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
    // This entire build method remains the same.
    final allBoxesAsync = ref.watch(allBoxesProvider);
    final totalPageCountAsync = ref.watch(totalPageCountProvider);

    if (allBoxesAsync.isLoading || totalPageCountAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (allBoxesAsync.hasError || totalPageCountAsync.hasError) {
      return Center(child: Text('Error loading Para data', style: TextStyle(fontSize: 14.sp)));
    }

    final paraPageRanges = ref.watch(paraPageRangesProvider);
    final currentPage = ref.read(currentPageProvider) + 1;

    if (!_isInitialStateSet && paraPageRanges.isNotEmpty) {
      int currentPara = 1;
      for (final entry in paraPageRanges.entries) {
        if (entry.value.contains(currentPage)) {
          currentPara = entry.key;
          break;
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedNavigationParaProvider.notifier).state = currentPara;
          ref.read(selectedNavigationPageProvider.notifier).state = currentPage;
          _paraScrollController.jumpTo(index: currentPara - 1);
          final pageList = paraPageRanges[currentPara] ?? [];
          final pageIndex = pageList.indexOf(currentPage);
          if (pageIndex != -1) {
            _pageScrollController.jumpTo(index: pageIndex);
          }
        }
      });
      _isInitialStateSet = true;
    }

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 1, child: _buildParaList(ref)),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(flex: 1, child: _buildRightPane(ref, paraPageRanges, currentPage)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    // This header logic remains the same.
    return Container(
      color: Theme.of(context).primaryColor,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text('পারা', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp, fontFamily: 'SolaimanLipi')),
          ),
          Expanded(
            flex: 1,
            child: Text('পাতা', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp, fontFamily: 'SolaimanLipi')),
          ),
        ],
      ),
    );
  }

  Widget _buildParaList(WidgetRef ref) {
    // This para list logic remains the same.
    final selectedPara = ref.watch(selectedNavigationParaProvider);
    final currentPage = ref.read(currentPageProvider) + 1;

    return ScrollablePositionedList.separated(
      itemScrollController: _paraScrollController,
      padding: EdgeInsets.zero,
      itemCount: 30,
      separatorBuilder: (context, index) => Divider(height: 1.h, color: Colors.grey.shade300),
      itemBuilder: (context, index) {
        final paraNumber = index + 1;
        final isSelected = paraNumber == selectedPara;

        return ListTile(
          tileColor: isSelected ? Theme.of(context).primaryColor : null,
          title: Center(
            child: Text(
              toBengaliNumber(paraNumber),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
          onTap: () {
            ref.read(selectedNavigationParaProvider.notifier).state = paraNumber;
            ref.read(selectedNavigationPageProvider.notifier).state = currentPage;
            ref.read(selectedAyahProvider.notifier).clear();
          },
        );
      },
    );
  }

  // --- THIS IS THE ONLY METHOD THAT CHANGES ---
  Widget _buildRightPane(WidgetRef ref, Map<int, List<int>> paraPageRanges, int currentPage) {
    final selectedPara = ref.watch(selectedNavigationParaProvider);
    final selectedPage = ref.watch(selectedNavigationPageProvider);
    final pageNumbers = paraPageRanges[selectedPara];

    if (pageNumbers == null || pageNumbers.isEmpty) {
      return Center(child: Text('পৃষ্ঠা তথ্য পাওয়া যায়নি', style: TextStyle(fontSize: 14.sp)));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageScrollController.isAttached) {
        final pageIndex = pageNumbers.indexOf(currentPage);
        if (pageIndex != -1) {
          _pageScrollController.jumpTo(index: pageIndex);
        }
      }
    });

    return ScrollablePositionedList.separated(
      itemScrollController: _pageScrollController,
      padding: EdgeInsets.zero,
      separatorBuilder: (context, index) => Divider(height: 1.h, color: Colors.grey.shade300),
      itemCount: pageNumbers.length,
      itemBuilder: (context, index) {
        // 1. Get the REAL page number for the onTap logic.
        final actualPageNumber = pageNumbers[index];

        // 2. The page number to DISPLAY is simply the index + 1.
        final displayPageNumber = index + 1;

        // 3. The selection check still uses the REAL page number.
        final isSelected = actualPageNumber == selectedPage;

        return ListTile(
          tileColor: isSelected ? Theme.of(context).primaryColor : null,
          title: Center(
            child: Text(
              // 4. We show the DISPLAY page number here.
              toBengaliNumber(displayPageNumber),
              style: TextStyle(
                fontSize: 14.sp,
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          onTap: () {
            // 5. But when tapped, we navigate to the REAL page number.
            ref.read(navigateToPageCommandProvider.notifier).state = actualPageNumber;
            ref.read(selectedAyahProvider.notifier).clear();
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}