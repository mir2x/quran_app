import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../viewmodel/ayah_highlight_viewmodel.dart';

// --- State Provider Modification ---
// It now defaults to 1, ensuring a para is always selected.
// We also remove autoDispose so the user's manual selection is remembered
// during a single app session if they close and reopen the drawer.
final selectedNavigationParaProvider = StateProvider<int>((_) => 1);


class ParaNavigationView extends ConsumerStatefulWidget {
  const ParaNavigationView({super.key});

  @override
  ConsumerState<ParaNavigationView> createState() => _ParaNavigationViewState();
}

class _ParaNavigationViewState extends ConsumerState<ParaNavigationView> {
  // Flag to ensure our "smart select" logic runs only once when the drawer opens.
  bool _isInitialParaSet = false;

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
    final totalPageCountAsync = ref.watch(totalPageCountProvider);

    if (allBoxesAsync.isLoading || totalPageCountAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (allBoxesAsync.hasError || totalPageCountAsync.hasError) {
      return Center(child: Text('Error loading Para data', style: TextStyle(fontSize: 14.sp)));
    }

    final paraPageRanges = ref.watch(paraPageRangesProvider);

    // --- SMART STATE RETENTION LOGIC ---
    // This runs after the data is loaded but only once per drawer opening.
    if (!_isInitialParaSet && paraPageRanges.isNotEmpty) {
      // Find which Para corresponds to the currently viewed page.
      final currentPage = ref.read(currentPageProvider) + 1; // Quran pages are 1-based
      int currentPara = 1; // Default to 1
      for (final entry in paraPageRanges.entries) {
        if (entry.value.contains(currentPage)) {
          currentPara = entry.key;
          break;
        }
      }

      // Safely update the provider state after the build is complete.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedNavigationParaProvider.notifier).state = currentPara;
        }
      });
      _isInitialParaSet = true;
    }
    // --- END OF SMART LOGIC ---

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 1, // Equal width
                child: _buildParaList(ref, paraPageRanges),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                flex: 1, // Equal width
                child: _buildRightPane(ref, paraPageRanges),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.green.shade800,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            flex: 1, // Equal width
            child: Text('পারা', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp, fontFamily: 'SolaimanLipi')),
          ),
          Expanded(
            flex: 1, // Equal width
            child: Text('পাতা', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp, fontFamily: 'SolaimanLipi')),
          ),
        ],
      ),
    );
  }

  Widget _buildParaList(WidgetRef ref, Map<int, List<int>> paraPageRanges) {
    final selectedPara = ref.watch(selectedNavigationParaProvider);

    return ListView.separated(
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
            ref.read(selectedAyahProvider.notifier).clear();
          },
        );
      },
    );
  }

  Widget _buildRightPane(WidgetRef ref, Map<int, List<int>> paraPageRanges) {
    final selectedPara = ref.watch(selectedNavigationParaProvider);
    final pageNumbers = paraPageRanges[selectedPara];

    if (pageNumbers == null || pageNumbers.isEmpty) {
      // This case should rarely happen now that a default is set.
      return Center(child: Text('পৃষ্ঠা তথ্য পাওয়া যায়নি', style: TextStyle(fontSize: 14.sp)));
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      separatorBuilder: (context, index) => Divider(height: 1.h, color: Colors.grey.shade300),
      itemCount: pageNumbers.length,
      itemBuilder: (context, index) {
        final pageNumber = pageNumbers[index];
        return ListTile(
          title: Center(
            child: Text(
              toBengaliNumber(pageNumber),
              style: TextStyle(fontSize: 14.sp, color: Colors.black87),
            ),
          ),
          onTap: () {
            ref.read(navigateToPageCommandProvider.notifier).state = pageNumber;
            ref.read(selectedAyahProvider.notifier).clear();
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}