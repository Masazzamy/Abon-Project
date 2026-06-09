import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserProvider extends ChangeNotifier {
  String? _fotoProfilPath;
  String _namaLengkap = 'Masazzamy'; // default fallback
  String _kedudukan = 'ceo'; // default role

  String? get fotoProfilPath => _fotoProfilPath;
  String get namaLengkap => _namaLengkap;
  String get kedudukan => _kedudukan;

  UserProvider() {
    loadUserData();
  }

  // Load from local storage
  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fotoProfilPath = prefs.getString('foto_profil');
      _namaLengkap = prefs.getString('nama') ?? 'Masazzamy';
      _kedudukan = prefs.getString('kedudukan') ?? 'ceo';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data in UserProvider: $e');
    }
  }

  // Update profile photo
  Future<void> updateFotoProfil(String? path) async {
    _fotoProfilPath = path;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (path != null) {
        await prefs.setString('foto_profil', path);
      } else {
        await prefs.remove('foto_profil');
      }
    } catch (e) {
      debugPrint('Error saving photo path in UserProvider: $e');
    }
  }

  // Update profile details
  Future<void> updateProfile({
    required String nama,
    required String kedudukan,
  }) async {
    _namaLengkap = nama;
    _kedudukan = kedudukan;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nama', nama);
      await prefs.setString('kedudukan', kedudukan);
    } catch (e) {
      debugPrint('Error saving profile info in UserProvider: $e');
    }
  }

  // Sync complete user data object from backend API response
  Future<void> syncFromBackend(Map<String, dynamic> userData) async {
    try {
      _namaLengkap = userData['name'] ?? _namaLengkap;
      // Stored role from DB
      _kedudukan = userData['role'] ?? _kedudukan;
      
      // Check if profile exists and has photo path or phone
      if (userData['profile'] != null) {
        final profile = userData['profile'] as Map<String, dynamic>;
        _fotoProfilPath = profile['photo_path'] ?? _fotoProfilPath;
      }
      
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nama', _namaLengkap);
      await prefs.setString('kedudukan', _kedudukan);
      if (_fotoProfilPath != null) {
        await prefs.setString('foto_profil', _fotoProfilPath!);
      }
      await prefs.setString('user_data', jsonEncode(userData));
    } catch (e) {
      debugPrint('Error syncing from backend in UserProvider: $e');
    }
  }
}
