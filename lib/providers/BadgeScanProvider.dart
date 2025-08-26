import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BadgeScanMode { any, specific }

class BadgeScanProvider with ChangeNotifier {
  BadgeScanMode _mode = BadgeScanMode.any;
  List<String> _badgeNames = ['LSLED', 'VBLAB'];
  bool _isLoaded = false;

  BadgeScanMode get mode => _mode;
  List<String> get badgeNames => List.unmodifiable(_badgeNames);
  bool get isLoaded => _isLoaded;

  BadgeScanProvider() {
    _loadFromPrefs(); // Load persisted values in background
  }

  // --- Persistence helpers ---
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Load scan mode
    final modeIndex = prefs.getInt('badge_scan_mode');
    if (modeIndex != null) {
      _mode = BadgeScanMode.values[modeIndex];
    }

    // Load badge names
    final storedNames = prefs.getStringList('badge_names');
    if (storedNames != null && storedNames.isNotEmpty) {
      _badgeNames = storedNames;
    }

    _isLoaded = true;
    notifyListeners(); // Notify UI that values are loaded
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('badge_scan_mode', _mode.index);
    await prefs.setStringList('badge_names', _badgeNames);
  }

  // --- Public methods to update values ---
  void setMode(BadgeScanMode mode) {
    _mode = mode;
    _saveToPrefs();
    notifyListeners();
  }

  void setBadgeNames(List<String> names) {
    _badgeNames = names.where((name) => name.trim().isNotEmpty).toList();
    _saveToPrefs();
    notifyListeners();
  }

  void addBadgeName(String name) {
    if (name.trim().isEmpty) return;
    _badgeNames.add(name.trim());
    _saveToPrefs();
    notifyListeners();
  }

  void removeBadgeNameAt(int index) {
    if (index < 0 || index >= _badgeNames.length) return;
    _badgeNames.removeAt(index);
    _saveToPrefs();
    notifyListeners();
  }

  void updateBadgeName(int index, String newName) {
    if (index < 0 || index >= _badgeNames.length) return;
    _badgeNames[index] = newName.trim();
    _saveToPrefs();
    notifyListeners();
  }
}
