import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> isDownloaded(String reciterId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('reciter_downloaded_$reciterId') ?? false;
}

Future<void> markAsDownloaded(String reciterId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('reciter_downloaded_$reciterId', true);
}

Future<String> getLocalPath(String reciterId) async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/$reciterId';
}