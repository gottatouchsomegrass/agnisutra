import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants.dart';

class IotService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> getLatestData() async {
    final box = await Hive.openBox('iot_cache');
    try {
      String? token = await _storage.read(key: 'access_token');

      final response = await _dio.get(
        '${AppConstants.baseUrl}/iot/latest',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        // Cache for offline use
        await box.put('latest', response.data);
        return response.data;
      }
      return null;
    } catch (e) {
      print('IoT Service Error: $e. Trying Hive cache...');
      // Return cached data on connection failure
      final cached = box.get('latest');
      if (cached != null) {
        return Map<String, dynamic>.from(cached);
      }
      return null;
    }
  }
}
