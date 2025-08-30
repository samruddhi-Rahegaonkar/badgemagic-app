import 'package:badgemagic/bademagic_module/bluetooth/base_ble_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/bluetooth/scan_state.dart';
import 'package:flutter/material.dart';

class StreamingProvider extends ChangeNotifier {
  bool _isStreaming = false;
  bool _isConnected = false;
  DataTransferManager? _manager; // 🔹 Keep persistent reference

  bool get isStreaming => _isStreaming;
  bool get isConnected => _isConnected;
  DataTransferManager? get manager => _manager; // expose if needed elsewhere

  Future<void> startStreaming() async {
    try {
      _manager = DataTransferManager.forStreaming();
      NormalBleState? state = ScanState(manager: _manager!);

      while (state != null) {
        state = (await state.processState()) as NormalBleState?;

        if (_manager!.isStreamingConnectionReady()) {
          _isStreaming = true;
          _isConnected = true;
          notifyListeners();
          return;
        }

        // prevent tight loop
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // ❌ If failed
      _isStreaming = false;
      _isConnected = false;
      _manager = null;
      notifyListeners();
    } catch (e) {
      _isStreaming = false;
      _isConnected = false;
      _manager = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> stopStreaming() async {
    _isStreaming = false;
    _isConnected = false;

    // 🔹 Cleanup BLE connection if manager exists
    try {
      await _manager?.exitStreamingMode();
      await _manager
          ?.disconnect(); // (make sure you implement disconnect in DataTransferManager)
    } catch (_) {
      // ignore cleanup errors
    }

    _manager = null;
    notifyListeners();
  }
}
