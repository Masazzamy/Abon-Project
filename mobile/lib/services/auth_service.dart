import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  static const String defaultBaseUrl = ApiConfig.defaultBaseUrl;

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final isCustom = prefs.getBool('is_custom_api_url') ?? false;
    if (!isCustom) {
      return defaultBaseUrl;
    }
    return prefs.getString('api_base_url') ?? defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
    await prefs.setBool('is_custom_api_url', true);
  }

  static Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_base_url');
    await prefs.setBool('is_custom_api_url', false);
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

  /// Ambil data profil dan settings dari API
  Future<Map<String, dynamic>> getProfile() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/profile');
    final token = await getToken();

    if (token == null) {
      return {
        'success': false,
        'message': 'Sesi telah berakhir. Silakan login kembali.'
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
        // Simpan data user terupdate di sesi lokal
        final prefs = await SharedPreferences.getInstance();
        final localUser = await getLocalUser() ?? {};
        localUser['name'] = responseData['data']['user']['name'];
        localUser['email'] = responseData['data']['user']['email'];
        await prefs.setString('user_data', jsonEncode(localUser));

        return {
          'success': true,
          'data': responseData['data']
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal memuat profil'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi server: $e'
      };
    }
  }

  /// Update data profil & settings ke API
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? businessName,
    String? businessAddress,
    bool? darkMode,
    bool? notificationsEnabled,
  }) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/profile');
    final token = await getToken();

    try {
      final response = await http.put(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'business_name': businessName,
          'business_address': businessAddress,
          'dark_mode': darkMode,
          'notifications_enabled': notificationsEnabled,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Simpan data user terupdate di sesi lokal
        final prefs = await SharedPreferences.getInstance();
        final localUser = await getLocalUser() ?? {};
        localUser['name'] = responseData['data']['user']['name'];
        localUser['email'] = responseData['data']['user']['email'];
        await prefs.setString('user_data', jsonEncode(localUser));

        return {
          'success': true,
          'message': responseData['message'] ?? 'Profil berhasil diperbarui',
          'data': responseData['data']
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal memperbarui profil',
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

  /// Ubah password user
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/profile/password');
    final token = await getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password berhasil diubah'
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mengubah password',
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

  /// Upload foto profil
  Future<Map<String, dynamic>> uploadPhoto(String filePath) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/profile/photo');
    final token = await getToken();

    try {
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.files.add(await http.MultipartFile.fromPath('photo', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Foto berhasil diunggah',
          'photo_url': responseData['photo_url']
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mengunggah foto'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi server: $e'
      };
    }
  }

  /// Ping Laravel API to test connection
  Future<Map<String, dynamic>> pingServer() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/ping');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Koneksi Berhasil',
          'time': responseData['time'] ?? '',
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal terhubung. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Server tidak merespon (Offline). Pastikan Laptop & HP tersambung ke WiFi yang sama. Detail: $e',
      };
    }
  }
}
