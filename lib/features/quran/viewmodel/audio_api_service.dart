import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/sura_audio_data.dart';

class AudioApiService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://islami-jindegi-backend.fly.dev';

  Future<SuraAudioData?> getSuraAudioUrls(String reciterId, int sura) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/get-sura-audio-urls',
        data: {
          'reciterId': reciterId,
          'sura': sura,
        },
      );
      if (response.statusCode == 200) {
        return SuraAudioData.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      print('Failed to get audio URLs: $e');
      return null;
    }
  }
}

final audioApiServiceProvider = Provider<AudioApiService>((ref) {
  return AudioApiService();
});