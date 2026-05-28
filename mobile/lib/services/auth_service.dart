import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Gunakan IP 10.0.2.2 untuk Android Emulator, 127.0.0.1 untuk Web / iOS Simulator.
  static const String defaultBaseUrl = kIsWeb
      ? 'http://127.0.0.1:8000/api'
      : 'http://10.0.2.2:8000/api';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_base_url') ?? defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Registrasi berhasil',
          'data': responseData['data']
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registrasi gagal',
          'errors': responseData['errors']
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi server: $e'
      };
    }
  }

  /// Login user and save token + user data
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final token = responseData['token'];
        final userData = responseData['user'];

        // Simpan token & user data di SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_data', jsonEncode(userData));

        return {
          'success': true,
          'message': responseData['message'] ?? 'Login berhasil',
          'token': token,
          'user': userData
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Email atau password salah'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi server: $e'
      };
    }
  }

  /// Get current authenticated user details from server
  Future<Map<String, dynamic>> getUser() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/user');
    final token = await getToken();

    if (token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login kembali.'
      };
    }

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Update user data lokal yang disimpan
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(responseData['data']));

        return {
          'success': true,
          'message': 'Data user berhasil diambil',
          'data': responseData['data']
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mengambil data user'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi server: $e'
      };
    }
  }

  /// Logout and delete local & remote token
  Future<Map<String, dynamic>> logout() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/logout');
    final token = await getToken();

    if (token == null) {
      await clearLocalSession();
      return {
        'success': true,
        'message': 'Logout berhasil (lokal)'
      };
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      await clearLocalSession();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Logout berhasil'
        };
      } else {
        return {
          'success': true,
          'message': 'Logout selesai'
        };
      }
    } catch (e) {
      await clearLocalSession();
      return {
        'success': true,
        'message': 'Koneksi gagal, sesi lokal berhasil dibersihkan'
      };
    }
  }

  /// Ambil token yang tersimpan di lokal
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Ambil data user yang tersimpan di lokal
  Future<Map<String, dynamic>?> getLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }

  /// Bersihkan data sesi lokal
  Future<void> clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  /// Periksa apakah user sudah login
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
