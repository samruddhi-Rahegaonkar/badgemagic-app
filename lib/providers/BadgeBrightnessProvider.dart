import 'package:flutter/material.dart';
import 'package:badgemagic/services/BleBrightnessService.dart';

class BadgeBrightnessProvider extends ChangeNotifier {
  final BleBrightnessService _bleBrightnessService;
  double _brightness = 50.0; // Default brightness level
  bool _isConnected = false;
  String _errorMessage = "";
  bool _isBrightnessVisible = false;

  // Getters
  double get brightness => _brightness;
  bool get isConnected => _isConnected;
  String get errorMessage => _errorMessage;
  bool get isBrightnessVisible => _isBrightnessVisible;

  BadgeBrightnessProvider(this._bleBrightnessService) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _bleBrightnessService.initialize();

    _bleBrightnessService.connectionStatus.listen((connected) {
      _isConnected = connected;
      notifyListeners();

      if (connected) {
        getCurrentBrightness();
      }
    });

    _bleBrightnessService.errorStream.listen((error) {
      _errorMessage = error;
      notifyListeners();
    });
  }

  void toggleBrightnessVisibility(bool value) {
    _isBrightnessVisible = value;
    notifyListeners();
  }

  Future<bool> connectToDevice(String deviceId) async {
    bool result = await _bleBrightnessService.connectToDevice(deviceId);
    if (result) {
      _errorMessage = "";
    }
    notifyListeners();
    return result;
  }

  Future<bool> setBrightness(double brightnessLevel) async {
    _brightness = brightnessLevel;
    notifyListeners();

    if (_isConnected) {
      bool success =
          await _bleBrightnessService.setBrightness(brightnessLevel.round());

      if (!success && _errorMessage.isEmpty) {
        _errorMessage = "Failed to update brightness";
        notifyListeners();
      }

      return success;
    }

    // If not connected, return true since we updated the local state
    return true;
  }

  Future<void> getCurrentBrightness() async {
    final currentBrightness =
        await _bleBrightnessService.getCurrentBrightness();
    if (currentBrightness != null) {
      _brightness = currentBrightness.toDouble();
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _bleBrightnessService.disconnect();
  }

  @override
  void dispose() {
    _bleBrightnessService.dispose();
    super.dispose();
  }
}
