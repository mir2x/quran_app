import 'package:flutter_riverpod/flutter_riverpod.dart';

final Map<String, String> reciters = {
  'আব্দুল্লাহ আল জুহানী': 'abdullah-al-joohani',
  'আব্দুর রহমান আল সুদাইস': 'abdur-rahman-al-sudais',
  'ফারিস আব্বাদ': 'farees-abbad',
  'মিশারি রাশিদ আলাফাসি': 'mishary-bin-rashid-alafasy',
  'আব্দুল বাসিত আব্দুস সামাদ': 'qari-abdul-basit',
  'মাহের আল মুয়াইক্বিলি': 'qari-maher-al-muaiqly',
  'সৌদ আল-শুরাইম': 'qari-saud-bin-ibrahim-ash-shuraim',
};

final selectedReciterProvider = StateProvider<String>((_) => reciters.values.first);