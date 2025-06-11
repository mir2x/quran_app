import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../model/ayah_box.dart';

final allBoxesProvider = FutureProvider<List<AyahBox>>((ref) async {
  final jsonStr = await rootBundle.loadString('assets/ayah_boxes.json');
  final decoded = jsonDecode(jsonStr) as List;
  return decoded.map((e) => AyahBox.fromJson(e)).toList(growable: false);
});

final boxesForPageProvider =
Provider.family<List<AyahBox>, int>((ref, pageIndex) {
  final all = ref.watch(allBoxesProvider).maybeWhen(
    data: (d) => d,
    orElse: () => const <AyahBox>[],
  );

  final logicalPage = pageIndex;
  if (logicalPage < kFirstPageNumber) {
    return const <AyahBox>[];
  }

  return all
      .where((b) => b.pageNumber == logicalPage)
      .toList(growable: false);
});


class SelectedAyahNotifier extends StateNotifier<int?> {
  SelectedAyahNotifier() : super(null);
  void select(int? ayah) => state = state == ayah ? null : ayah;
  void clear()           => state = null;
}

final selectedAyahProvider =
StateNotifierProvider<SelectedAyahNotifier, int?>(
        (ref) => SelectedAyahNotifier());

final currentPageProvider = StateProvider<int>((_) => 0);