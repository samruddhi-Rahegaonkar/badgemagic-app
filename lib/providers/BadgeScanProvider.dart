import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BadgeScanMode { any, specific }

class BadgeScanProvider with ChangeNotifier {
  BadgeScanMode _mode = BadgeScanMode.any;
  List<String> _badgeNames = ['LSLED', 'VBLAB'];
  Set<String> _selectedBadgeNames = {};
  bool _isLoaded = false;

  BadgeScanMode get mode => _mode;
  List<String> get badgeNames => List.unmodifiable(_badgeNames);
  Set<String> get selectedBadgeNames => Set.unmodifiable(_selectedBadgeNames);
  bool get isLoaded => _isLoaded;

  BadgeScanProvider() {
    _loadFromPrefs();
  }

  // ===============================
  // LOAD FROM PREFERENCES
  // ===============================
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final modeIndex = prefs.getInt('badge_scan_mode');
    if (modeIndex != null &&
        modeIndex >= 0 &&
        modeIndex < BadgeScanMode.values.length) {
      _mode = BadgeScanMode.values[modeIndex];
    }

    final storedNames = prefs.getStringList('badge_names');
    if (storedNames != null && storedNames.isNotEmpty) {
      _badgeNames = storedNames;
    }

    final storedSelected = prefs.getStringList('selected_badge_names');
    if (storedSelected != null) {
      _selectedBadgeNames = storedSelected.where(_badgeNames.contains).toSet();
    }

    _isLoaded = true;
    notifyListeners();
  }

  // ===============================
  // SAVE TO PREFERENCES
  // ===============================
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('badge_scan_mode', _mode.index);
    await prefs.setStringList('badge_names', _badgeNames);

    await prefs.setStringList(
      'selected_badge_names',
      _selectedBadgeNames.toList(),
    );
  }

  // ===============================
  // MODE
  // ===============================
  void setMode(BadgeScanMode mode) {
    _mode = mode;
    _saveToPrefs();
    notifyListeners();
  }

  // ===============================
  // BADGE NAMES
  // ===============================
  void setBadgeNames(List<String> names) {
    _badgeNames = names.where((name) => name.trim().isNotEmpty).toList();

    // Remove selections that no longer exist
    _selectedBadgeNames.removeWhere((name) => !_badgeNames.contains(name));

    _saveToPrefs();
    notifyListeners();
  }

  void addBadgeName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    _badgeNames.add(trimmed);
    _saveToPrefs();
    notifyListeners();
  }

  void removeBadgeNameAt(int index) {
    if (index < 0 || index >= _badgeNames.length) return;

    final removedName = _badgeNames[index];
    _badgeNames.removeAt(index);

    _selectedBadgeNames.remove(removedName);

    _saveToPrefs();
    notifyListeners();
  }

  void updateBadgeName(int index, String newName) {
    if (index < 0 || index >= _badgeNames.length) return;

    final oldName = _badgeNames[index];
    final trimmed = newName.trim();

    _badgeNames[index] = trimmed;

    // Update selection if name changed
    if (_selectedBadgeNames.contains(oldName)) {
      _selectedBadgeNames.remove(oldName);
      _selectedBadgeNames.add(trimmed);
    }

    _saveToPrefs();
    notifyListeners();
  }

  // ===============================
  // SELECTION LOGIC
  // ===============================
  void toggleSelection(int index) {
    if (index < 0 || index >= _badgeNames.length) return;

    final badgeName = _badgeNames[index];

    if (_selectedBadgeNames.contains(badgeName)) {
      _selectedBadgeNames.remove(badgeName);
    } else {
      _selectedBadgeNames.add(badgeName);
    }

    _saveToPrefs();
    notifyListeners();
  }

  bool isSelected(int index) {
    if (index < 0 || index >= _badgeNames.length) return false;
    return _selectedBadgeNames.contains(_badgeNames[index]);
  }

  void clearSelection() {
    _selectedBadgeNames.clear();
    _saveToPrefs();
    notifyListeners();
  }

  void selectAll() {
    _selectedBadgeNames = _badgeNames.toSet();
    _saveToPrefs();
    notifyListeners();
  }

  void removeSelectedDevices() {
    if (_selectedBadgeNames.isEmpty) return;

    _badgeNames.removeWhere((name) => _selectedBadgeNames.contains(name));

    _selectedBadgeNames.clear();

    _saveToPrefs();
    notifyListeners();
  }

  List<String> getSelectedBadgeNames() {
    return _selectedBadgeNames.toList();
  }
}
