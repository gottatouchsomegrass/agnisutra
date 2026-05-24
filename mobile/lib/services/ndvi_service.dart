import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants.dart';

class NdviService {
  static const String baseUrl = AppConstants.baseUrl + '/krishi-saathi';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<Map<String, dynamic>> fetchNdvi(double lat, double lon) async {
    final box = await Hive.openBox('ndvi_cache');
    // Prefer cache keyed by lat/lon for location accuracy
    final cacheKey = 'ndvi_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';

    try {
      final response = await _dio.get(
        '/ndvi',
        queryParameters: {'lat': lat, 'lon': lon},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        // Save to Hive for offline use
        await box.put(cacheKey, data);
        await box.put('last_ndvi', data); // Generic fallback key
        return data;
      } else {
        throw Exception('Failed to load NDVI data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Return cached data on any network failure
      final cached = box.get(cacheKey) ?? box.get('last_ndvi');
      if (cached != null) {
        return Map<String, dynamic>.from(cached);
      }
      if (e.response != null) {
        throw Exception('Server error: ${e.response?.data ?? e.message}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      // Return cached data on any other error
      final cached = box.get(cacheKey) ?? box.get('last_ndvi');
      if (cached != null) {
        return Map<String, dynamic>.from(cached);
      }
      throw Exception('Error fetching NDVI: $e');
    }
  }
}
