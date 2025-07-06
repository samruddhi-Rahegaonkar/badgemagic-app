import 'package:flutter/material.dart';

class BadgeAliasProvider with ChangeNotifier {
  final Map<String, String> _aliases = {};

  String? getAlias(String deviceId) => _aliases[deviceId];

  void setAlias(String deviceId, String alias) {
    _aliases[deviceId] = alias;
    notifyListeners();
  }

  void removeAlias(String deviceId) {
    _aliases.remove(deviceId);
    notifyListeners();
  }

  void clearAll() {
    _aliases.clear();
    notifyListeners();
  }

  Map<String, String> get allAliases => Map.unmodifiable(_aliases);
}
