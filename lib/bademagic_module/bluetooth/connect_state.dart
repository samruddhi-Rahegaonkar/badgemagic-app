import 'package:badgemagic/bademagic_module/bluetooth/base_ble_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/completed_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/bluetooth/write_state.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ConnectState extends NormalBleState {
  final ScanResult scanResult;
  final DataTransferManager manager;

  ConnectState({required this.scanResult, required this.manager});

  @override
  Future<BleState?> processState() async {
    BluetoothDevice device = scanResult.device;
    manager.connectedDevice = device;

    try {
      toast.showToast("Connecting to ${device.platformName}...");
      logger.d("Attempting to connect to ${device.platformName}...");

      await device.connect(autoConnect: false);
      await Future.delayed(const Duration(milliseconds: 500));

      logger.d("Connected to device: ${device.platformName}");
      toast.showToast("Connected to ${device.platformName}");

      return WriteState(manager: manager, device: device);
    } catch (e) {
      logger.e("Connection failed: $e");
      return CompletedState(
        isSuccess: false,
        message: "Failed to connect to device. Please retry.",
        mode: manager.mode,
        shouldDisconnect: true, // ensure cleanup
      );
    }
  }
}
