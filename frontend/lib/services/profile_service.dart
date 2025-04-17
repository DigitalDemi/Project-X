import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService extends ChangeNotifier {
  static const String _imagePathKey = 'profile_image_path';
  String? _imagePath;

  ProfileService() {
    loadImagePath(); // Load saved path when service is created
  }

  String? get imagePath => _imagePath;

  Future<void> loadImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    _imagePath = prefs.getString(_imagePathKey);
    notifyListeners();
  }

  Future<void> saveImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_imagePathKey, path);
    _imagePath = path;
    notifyListeners();
  }
}