import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../constants.dart';

class SatelliteService {
  final String baseUrl = AppConstants.baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> getSatelliteData(double lat, double lon) async {
    // Fallback data used on any error
    final Map<String, dynamic> fallback = {
      "ndvi_peak": 0.75,
      "ndvi_flowering": 0.70,
      "ndvi_veg_slope": 0.01,
      "ndvi_image": null,
      "samples_analyzed": 0,
      "source": "offline_fallback",
    };

    try {
      final token = await _storage.read(key: 'access_token');
      final uri = Uri.parse(
        '$baseUrl/krishi-saathi/ndvi?lat=$lat&lon=$lon',
      );

      print('Fetching satellite/NDVI data from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${token ?? ''}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Cache in Hive for offline use
        final box = await Hive.openBox('satellite_cache');
        await box.put('last_data', data);
        return data;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Satellite Service Error: $e. Trying Hive cache...');
      try {
        final box = await Hive.openBox('satellite_cache');
        final cached = box.get('last_data');
        if (cached != null) {
          return Map<String, dynamic>.from(cached);
        }
      } catch (_) {}
      print('No cache found. Using fallback data.');
      return fallback;
    }
  }
}
