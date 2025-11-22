import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/prediction_model.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class DiseaseApi {
  static const String baseUrl = 'https://mitran-disease-detection.onrender.com';

  Future<bool> checkHealth() async {
    try {
      debugPrint('detect: health check start');
      final response = await http.get(Uri.parse('$baseUrl/health'));
      debugPrint('detect: health check status ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('detect: health check error $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> predict(File imageFile) async {
    debugPrint('detect: predict start ${imageFile.path}');
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/predict'),
    );
    final ext = imageFile.path.toLowerCase();
    MediaType contentType;
    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) {
      contentType = MediaType('image', 'jpeg');
    } else if (ext.endsWith('.png')) {
      contentType = MediaType('image', 'png');
    } else {
      contentType = MediaType('application', 'octet-stream');
    }
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path, contentType: contentType));
    request.headers['Accept'] = 'application/json';
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    debugPrint('detect: predict status ${response.statusCode}');
    if (response.statusCode == 200) {
      final body = response.body;
      debugPrint('detect: predict ok');
      return json.decode(body);
    }
    if (response.statusCode == 400) {
      debugPrint('detect: backend reports unsupported file type');
      throw Exception('Unsupported file type');
    }
    if (response.statusCode == 503) {
      debugPrint('detect: backend model not ready');
      throw Exception('Model not ready');
    }
    throw Exception('Failed to predict: ${response.body}');
  }

  Future<Map<String, dynamic>> analyzeImage(XFile image, String userId) async {
    try {
      final file = File(image.path);
      final res = await predict(file);
      final item = res;
      final model = PredictionModel(
        imageUrl: '',
        label: item['label']?.toString() ?? 'Unknown',
        confidence: (item['confidence'] ?? 0).toDouble(),
        title: item['title']?.toString() ?? '',
        description: item['description']?.toString() ?? '',
        symptoms: List<String>.from(item['symptoms'] ?? []),
        treatments: List<String>.from(item['treatments'] ?? []),
        homecare: List<String>.from(item['homecare'] ?? []),
        note: item['note']?.toString() ?? '',
        userId: userId,
        timestamp: DateTime.now(),
      );
      return {'success': true, 'predictions': [model]};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
