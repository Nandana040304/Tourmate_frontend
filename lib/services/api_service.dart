import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ApiService {
  // Change to your server IP
  static const String baseUrl = 'http://192.168.1.7:8000/api';

  // Single text translation
  static Future<String> translateText(
      String text, {
        String sourceLanguage = 'ml',
        String targetLanguage = 'en',
      }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/translator/translate/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'source_language': sourceLanguage,
          'target_language': targetLanguage,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translated_text'] ?? 'Translation failed';
      }
      return 'Error: ${response.statusCode}';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  // OCR + Translate from image
  static Future<Map<String, String>> ocrAndTranslate(
      String imagePath, {
        String sourceLanguage = 'ml',
        String targetLanguage = 'en',
      }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/translator/ocr/translate/'),
      );

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('image', imagePath),
      );

      // Add language parameters
      request.fields['source_language'] = sourceLanguage;
      request.fields['target_language'] = targetLanguage;
      request.fields['ocr_language'] = 'mal'; // Malayalam

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'extracted_text': data['extracted_text'] ?? '',
          'translated_text': data['translated_text'] ?? '',
          'success': 'true',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'error': data['error'] ?? 'OCR failed',
          'success': 'false',
        };
      }
    } catch (e) {
      return {
        'error': 'Network error: $e',
        'success': 'false',
      };
    }
  }

  // Just OCR without translation
  static Future<String> extractTextFromImage(
      String imagePath, {
        String ocrLanguage = 'mal',
      }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/translator/ocr/'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('image', imagePath),
      );
      request.fields['language'] = ocrLanguage;

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['extracted_text'] ?? 'No text extracted';
      }
      return 'OCR Error';
    } catch (e) {
      return 'Network error: $e';
    }
  }
}