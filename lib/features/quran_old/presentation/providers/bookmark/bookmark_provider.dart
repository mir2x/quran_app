import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bookmark.dart';
import 'bookmark_notifier.dart';

final bookmarkProvider =
AsyncNotifierProvider<BookmarkNotifier, List<Bookmark>>(BookmarkNotifier.new);