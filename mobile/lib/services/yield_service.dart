import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants.dart';

class YieldService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 1. Yield Prediction (POST) - currently returns benchmark from backend
  Future<Map<String, dynamic>?> getPrediction(
    Map<String, dynamic> formData,
  ) async {
    final box = await Hive.openBox('last_prediction');
    try {
      String? token = await _storage.read(key: 'access_token');

      final response = await _dio.post(
        '${AppConstants.baseUrl}/krishi-saathi/predict',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        await box.put('data', response.data);
        return response.data;
      } else {
        print('Prediction failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Prediction error: $e');
      // Return cached prediction on connection failure
      if (box.isNotEmpty) {
        return Map<String, dynamic>.from(box.get('data'));
      }
      return null;
    }
  }

  // 2. IoT Data — with Hive fallback
  Future<Map<String, dynamic>?> getIoTData() async {
    final box = await Hive.openBox('iot_cache');
    try {
      String? token = await _storage.read(key: 'access_token');
      if (token == null) return null;

      final response = await _dio.get(
        '${AppConstants.baseUrl}/iot/latest',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        // Cache latest IoT reading
        await box.put('latest', response.data);
        return response.data;
      } else {
        print('IoT Data failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('IoT Data error: $e. Trying Hive cache...');
      // Return cached data on failure
      final cached = box.get('latest');
      if (cached != null) {
        return Map<String, dynamic>.from(cached);
      }
      return null;
    }
  }

  // 3. Weather Data — with Hive fallback
  Future<Map<String, dynamic>?> getWeatherData(double lat, double lon) async {
    final box = await Hive.openBox('weather_cache');
    try {
      String? token = await _storage.read(key: 'access_token');
      if (token == null) return null;

      final response = await _dio.get(
        '${AppConstants.baseUrl}/krishi-saathi/weather',
        queryParameters: {'lat': lat, 'lon': lon},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        await box.put('last_weather', response.data);
        return response.data;
      }
      return null;
    } catch (e) {
      print('Weather Data error: $e. Trying Hive cache...');
      final cached = box.get('last_weather');
      if (cached != null) {
        return Map<String, dynamic>.from(cached);
      }
      return null;
    }
  }

  // 4. Yield Prediction (GET) — lightweight params
  Future<Map<String, dynamic>?> getYieldPrediction({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double temperature,
    required double humidity,
    required double rainfall,
    required double ph,
    required String crop,
  }) async {
    final box = await Hive.openBox('yield_prediction_cache');
    try {
      String? token = await _storage.read(key: 'access_token');

      final response = await _dio.get(
        '${AppConstants.baseUrl}/krishi-saathi/get-yield-prediction',
        queryParameters: {
          'nitrogen': nitrogen,
          'phosphorus': phosphorus,
          'potassium': potassium,
          'temperature': temperature,
          'humidity': humidity,
          'rainfall': rainfall,
          'ph': ph,
          'crop': crop,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        await box.put('data', response.data);
        return response.data;
      }
      return null;
    } catch (e) {
      print('Yield Prediction error: $e. Trying Hive cache...');
      final cached = box.get('data');
      if (cached != null) {
        return Map<String, dynamic>.from(cached);
      }
      return null;
    }
  }

  // 5. NDVI Data — with Hive fallback
  Future<Map<String, dynamic>?> getNDVI(double lat, double lon) async {
    final box = await Hive.openBox('ndvi_cache');
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}/krishi-saathi/ndvi',
        queryParameters: {'lat': lat, 'lon': lon},
      );

      if (response.statusCode == 200) {
        await box.put('data', response.data);
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching NDVI: $e. Trying Hive cache...');
      final cached = box.get('data');
      if (cached != null) {
        return Map<String, dynamic>.from(cached);
      }
      return null;
    }
  }

  // 6. Fertilizer Recommendation — with Hive fallback
  Future<Map<String, dynamic>?> getFertilizerRecommendation({
    required String crop,
    required double targetYield,
    required double soilN,
    required double soilP,
    required double soilK,
    required double temperature,
    required double moisture,
    double ph = 6.5,
    int? fieldId,
  }) async {
    final box = await Hive.openBox('last_recommendation');
    try {
      String? token = await _storage.read(key: 'access_token');

      final data = {
        "soil_N": soilN,
        "soil_P": soilP,
        "soil_K": soilK,
        "temperature": temperature,
        "humidity": 60.0,
        "moisture": moisture,
        "ph": ph,
        "crop": crop,
        "target_yield": targetYield,
      };
      if (fieldId != null) data["field_id"] = fieldId;

      final response = await _dio.post(
        '${AppConstants.baseUrl}/krishi-saathi/recommend',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        await box.put('data', response.data);
        return response.data;
      }
      return null;
    } catch (e) {
      print('Fertilizer Recommendation error: $e. Trying Hive cache...');
      final cached = box.get('data');
      if (cached != null) {
        return Map<String, dynamic>.from(cached);
      }
      return null;
    }
  }
}
