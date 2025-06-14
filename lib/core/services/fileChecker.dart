import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> isAssetDownloaded(String id) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('reciter_downloaded_$id') ?? false;
}

Future<void> markAsDownloaded(String id) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('reciter_downloaded_$id', true);
}

Future<String> getLocalPath(String id) async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/$id';
}