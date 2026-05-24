import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class FieldService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> createField({
    required String name,
    required String crop,
    required double areaAcres,
    required double lat,
    required double lon,
  }) async {
    try {
      String? token = await _storage.read(key: 'access_token');
      if (token == null) return null;

      final response = await _dio.post(
        '${AppConstants.baseUrl}/krishi-saathi/fields',
        data: {
          'name': name,
          'crop': crop,
          'area_acres': areaAcres,
          'lat': lat,
          'lon': lon,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Error creating field: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getFields() async {
    try {
      String? token = await _storage.read(key: 'access_token');
      if (token == null) return null;

      final response = await _dio.get(
        '${AppConstants.baseUrl}/krishi-saathi/fields',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return null;
    } catch (e) {
      print('Error fetching fields: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getFieldRecommendation(int fieldId, {String? crop}) async {
    try {
      String? token = await _storage.read(key: 'access_token');
      if (token == null) return null;

      final queryParams = <String, dynamic>{};
      if (crop != null) queryParams['crop'] = crop;

      final response = await _dio.get(
        '${AppConstants.baseUrl}/krishi-saathi/fields/$fieldId/recommendation',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (e) {
      print('Error fetching recommendation: $e');
      return null;
    }
  }

  Future<bool> linkRecordToField(int recordId, int fieldId) async {
    try {
      String? token = await _storage.read(key: 'access_token');
      if (token == null) return false;

      final response = await _dio.patch(
        '${AppConstants.baseUrl}/krishi-saathi/yield-records/$recordId/link-field',
        queryParameters: {'field_id': fieldId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error linking record to field: $e');
      return false;
    }
  }

  Future<bool> deleteField(int fieldId) async {
    try {
      String? token = await _storage.read(key: 'access_token');
      if (token == null) return false;

      final response = await _dio.delete(
        '${AppConstants.baseUrl}/krishi-saathi/fields/$fieldId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting field: $e');
      return false;
    }
  }
}
