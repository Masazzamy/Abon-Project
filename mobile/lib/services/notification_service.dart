import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  final _authService = AuthService();

  /// Fetch all notifications for the current user, optionally filtered by type
  Future<Map<String, dynamic>> getNotifications({String tipe = 'semua'}) async {
    final baseUrl = await AuthService.getBaseUrl();
    final url = Uri.parse('$baseUrl/notifications?tipe=$tipe');
    final token = await _authService.getToken();

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
        final List<dynamic> notifListJson = responseData['data']['notifications'] ?? [];
        final List<NotifikasiModel> notifications = notifListJson
            .map((json) => NotifikasiModel.fromJson(json as Map<String, dynamic>))
            .toList();

        final Map<String, dynamic> unreadCounts = responseData['data']['unread_counts'] ?? {
          'semua': 0, 'stok': 0, 'transaksi': 0, 'laporan': 0, 'sistem': 0, 'promo': 0
        };

        return {
          'success': true,
          'notifications': notifications,
          'unread_counts': unreadCounts,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mengambil notifikasi'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi server: $e'
      };
    }
  }

  /// Mark a single notification as read
  Future<Map<String, dynamic>> markAsRead(String id) async {
    final baseUrl = await AuthService.getBaseUrl();
    final url = Uri.parse('$baseUrl/notifications/$id/read');
    final token = await _authService.getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': NotifikasiModel.fromJson(responseData['data'] as Map<String, dynamic>)
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal menandai dibaca'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi server: $e'
      };
    }
  }

  /// Mark a single notification as unread
  Future<Map<String, dynamic>> markAsUnread(String id) async {
    final baseUrl = await AuthService.getBaseUrl();
    final url = Uri.parse('$baseUrl/notifications/$id/unread');
    final token = await _authService.getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': NotifikasiModel.fromJson(responseData['data'] as Map<String, dynamic>)
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal menandai belum dibaca'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi server: $e'
      };
    }
  }

  /// Mark all notifications as read
  Future<Map<String, dynamic>> markAllAsRead() async {
    final baseUrl = await AuthService.getBaseUrl();
    final url = Uri.parse('$baseUrl/notifications/read-all');
    final token = await _authService.getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message']
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal menandai semua dibaca'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi server: $e'
      };
    }
  }

  /// Delete a single notification
  Future<Map<String, dynamic>> deleteNotification(String id) async {
    final baseUrl = await AuthService.getBaseUrl();
    final url = Uri.parse('$baseUrl/notifications/$id');
    final token = await _authService.getToken();

    try {
      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message']
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal menghapus notifikasi'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi server: $e'
      };
    }
  }

  /// Clear all notifications (with safety for critical ones on backend)
  Future<Map<String, dynamic>> clearAllNotifications() async {
    final baseUrl = await AuthService.getBaseUrl();
    final url = Uri.parse('$baseUrl/notifications/clear-all');
    final token = await _authService.getToken();

    try {
      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message']
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal menghapus semua notifikasi'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi server: $e'
      };
    }
  }

  /// Get user notification preferences
  Future<Map<String, dynamic>> getSettings() async {
    final baseUrl = await AuthService.getBaseUrl();
    final url = Uri.parse('$baseUrl/notifications/settings');
    final token = await _authService.getToken();

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
        return {
          'success': true,
          'settings': NotifikasiSettingModel.fromJson(responseData['data'] as Map<String, dynamic>)
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal memuat pengaturan'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi server: $e'
      };
    }
  }

  /// Update user notification preferences
  Future<Map<String, dynamic>> updateSettings(NotifikasiSettingModel settings) async {
    final baseUrl = await AuthService.getBaseUrl();
    final url = Uri.parse('$baseUrl/notifications/settings');
    final token = await _authService.getToken();

    try {
      final response = await http.put(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(settings.toJson()),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'],
          'settings': NotifikasiSettingModel.fromJson(responseData['data'] as Map<String, dynamic>)
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal memperbarui pengaturan'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi server: $e'
      };
    }
  }
}
