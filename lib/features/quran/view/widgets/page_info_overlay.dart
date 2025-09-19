import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran_app/core/utils/bengali_digit_extension.dart';
import 'package:quran_app/features/quran/viewmodel/ayah_highlight_viewmodel.dart';

class PageInfoOverlay extends ConsumerWidget {
  final int pageIndex;

  const PageInfoOverlay({super.key, required this.pageIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageInfo = ref.watch(pageInfoProvider(pageIndex + 1));
    final suraNamesList = ref.watch(suraNamesProvider);
    final isVisible = ref.watch(pageInfoVisibilityProvider);
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: IgnorePointer(
        ignoring: !isVisible,
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pageInfo.paraNumber != null)
                  Text(
                    'পারা ${pageInfo.paraNumber?.toBengaliDigit()}: ${pageInfo.pageNumber.toBengaliDigit()}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                SizedBox(height: 8.h),
                ...pageInfo.suraAyahRanges.entries.map((entry) {
                  final suraNumber = entry.key;
                  final (startAyah, endAyah) = entry.value;
                  final suraName = suraNamesList[suraNumber - 1];

                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '$suraName : ${startAyah.toBengaliDigit()} - ${endAyah.toBengaliDigit()}',
                      style: TextStyle(color: Colors.white, fontSize: 16.sp),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
