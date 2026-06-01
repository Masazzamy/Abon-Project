import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class ApiClient {
  static const Duration timeoutDuration = Duration(seconds: 7);

  /// Performs a GET request
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final baseUrl = await AuthService.getBaseUrl();
    final url = Uri.parse('$baseUrl/$endpoint');
    final token = await AuthService().getToken();

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException catch (e) {
      return _handleOfflineError(e);
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  /// Performs a POST request
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final baseUrl = await AuthService.getBaseUrl();
    final url = Uri.parse('$baseUrl/$endpoint');
    final token = await AuthService().getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException catch (e) {
      return _handleOfflineError(e);
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final responseData = jsonDecode(response.body);
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      
      return {
        'success': isSuccess,
        'statusCode': response.statusCode,
        'data': responseData['data'] ?? responseData,
        'message': responseData['message'] ?? (isSuccess ? 'Berhasil' : 'Permintaan gagal'),
        'errors': responseData['errors']
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal membaca respon dari server (Format Error).',
      };
    }
  }

  static Map<String, dynamic> _handleOfflineError(SocketException error) {
    return {
      'success': false,
      'isOffline': true,
      'message': 'Server tidak terjangkau. Pastikan laptop dan HP Android berada dalam jaringan Wi-Fi/Hotspot yang sama, dan server Laravel Anda sedang berjalan.'
    };
  }

  static Map<String, dynamic> _handleGenericError(dynamic error) {
    return {
      'success': false,
      'message': 'Terjadi kesalahan koneksi: ${error.toString()}'
    };
  }
}
