import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/enhancement_models.dart';

class ApiService {
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.healthEndpoint}'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  static Future<List<EnhancementMethod>> getEnhancementMethods() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.methodsEndpoint}'))
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final methodsList = data['methods'] as List;
        return methodsList
            .map((m) => EnhancementMethod.fromJson(m as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load enhancement methods');
      }
    } catch (e) {
      print('Error fetching methods: $e');
      rethrow;
    }
  }

  static Future<Uint8List> _compressImage(File imageFile) async {
    // Get file size
    final fileSize = await imageFile.length();

    // If file is already small enough, don't compress
    if (fileSize <= ApiConfig.maxImageSize) {
      return await imageFile.readAsBytes();
    }

    // Compress the image
    final result = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      quality: ApiConfig.compressionQuality,
      minWidth: 1920,
      minHeight: 1920,
    );

    return result ?? await imageFile.readAsBytes();
  }

  static Future<EnhancementResult> enhanceImage({
    required File imageFile,
    String method = 'auto',
  }) async {
    try {
      // Compress image
      final compressedBytes = await _compressImage(imageFile);

      // Create multipart request
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.enhanceImageEndpoint}',
      );
      final request = http.MultipartRequest('POST', uri);

      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          compressedBytes,
          filename: imageFile.path.split('/').last,
        ),
      );

      // Add method parameter
      request.fields['method'] = method;

      // Send request
      final streamedResponse = await request.send().timeout(
        ApiConfig.requestTimeout,
      );

      // Get response
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return EnhancementResult.fromJson(data);
        } else {
          throw Exception(data['error'] ?? 'Enhancement failed');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Server error');
      }
    } on SocketException {
      throw Exception(
        'Cannot connect to server. Make sure Flask backend is running.',
      );
    } on http.ClientException {
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      print('Error enhancing image: $e');
      rethrow;
    }
  }

  static Uint8List decodeBase64Image(String base64String) {
    // Remove data URI prefix if present
    String cleanBase64 = base64String;
    if (base64String.contains(',')) {
      cleanBase64 = base64String.split(',')[1];
    }

    return base64Decode(cleanBase64);
  }
}
