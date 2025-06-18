import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/bookmark.dart';

class BookmarkNotifier extends AsyncNotifier<List<Bookmark>> {
  @override
  Future<List<Bookmark>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('bookmarks') ?? [];
    return raw.map((e) => Bookmark.fromJson(jsonDecode(e))).toList();
  }

  Future<void> add(Bookmark b) async {
    final list = List<Bookmark>.from(state.value ?? []);
    if (list.any((e) => e.identifier == b.identifier)) return;
    list.add(b);
    state = AsyncData(list);
    await _persist(list);
  }

  Future<void> remove(String id) async {
    final list = List<Bookmark>.from(state.value ?? []);
    list.removeWhere((b) => b.identifier == id);
    state = AsyncData(list);
    await _persist(list);
  }

  Future<void> _persist(List<Bookmark> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'bookmarks', data.map((b) => jsonEncode(b.toJson())).toList());
  }

  bool isAyahBookmarked(int sura, int ayah) {
    if (!state.hasValue || state.value == null) {
      return false;
    }
    return state.value!.any(
          (b) => b.type == 'ayah' && b.sura == sura && b.ayah == ayah,
    );
  }

  bool isPageBookmarked(int page) {
    if (!state.hasValue || state.value == null) {
      return false;
    }
    return state.value!.any(
          (b) => b.type == 'page' && b.page == page,
    );
  }
}

final bookmarkProvider =
AsyncNotifierProvider<BookmarkNotifier, List<Bookmark>>(BookmarkNotifier.new);
