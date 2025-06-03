import 'package:flutter/material.dart';

enum BadgeScanMode { any, specific }

class BadgeScanProvider with ChangeNotifier {
  BadgeScanMode _mode = BadgeScanMode.any;
  List<String> _badgeNames = ['LSLED', 'VBLAB'];

  BadgeScanMode get mode => _mode;
  List<String> get badgeNames => List.unmodifiable(_badgeNames);

  void setMode(BadgeScanMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setBadgeNames(List<String> names) {
    _badgeNames = names.where((name) => name.trim().isNotEmpty).toList();
    notifyListeners();
  }

  void addBadgeName(String name) {
    _badgeNames.add(name);
    notifyListeners();
  }

  void removeBadgeNameAt(int index) {
    _badgeNames.removeAt(index);
    notifyListeners();
  }

  void updateBadgeName(int index, String newName) {
    _badgeNames[index] = newName;
    notifyListeners();
  }
}
