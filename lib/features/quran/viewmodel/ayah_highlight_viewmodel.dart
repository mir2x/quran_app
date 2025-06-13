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


class SelectedAyahState {
  final int ayahNumber;
  final Rect anchorRect;

  const SelectedAyahState(this.ayahNumber, this.anchorRect);
}

class SelectedAyahNotifier extends StateNotifier<SelectedAyahState?> {
  SelectedAyahNotifier() : super(null);

  void select(int ayah, Rect anchorRect) {
    if (state?.ayahNumber == ayah) {
      state = null;
    } else {
      state = SelectedAyahState(ayah, anchorRect);
    }
  }

  void clear() => state = null;
}

final selectedAyahProvider =
StateNotifierProvider<SelectedAyahNotifier, SelectedAyahState?>(
        (ref) => SelectedAyahNotifier());

final currentPageProvider = StateProvider<int>((_) => 0);

class TouchModeNotifier extends StateNotifier<bool> {
  TouchModeNotifier() : super(false);
  void toggle() => state = !state;
}

final touchModeProvider =
StateNotifierProvider<TouchModeNotifier, bool>((_) => TouchModeNotifier());

/// simple orientation toggle
class OrientationToggle {
  static bool _isPortraitOnly = true;

  static Future<void> toggle() async {
    _isPortraitOnly = !_isPortraitOnly;
    if (_isPortraitOnly) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    }
  }
}

class DrawerNotifier extends StateNotifier<bool> {
  DrawerNotifier() : super(false);          // false = closed
  void open()  => state = true;
  void close() => state = false;
}

final drawerOpenProvider =
StateNotifierProvider<DrawerNotifier, bool>((_) => DrawerNotifier());