import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/bluetooth/write_state.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'base_ble_state.dart';

class ConnectState extends RetryBleState {
  final ScanResult scanResult;
  final DataTransferManager manager;

  ConnectState({required this.manager, required this.scanResult});

  @override
  Future<BleState?> processState() async {
    try {
      // Check if already connected before trying to connect
      BluetoothConnectionState currentState =
          await scanResult.device.connectionState.first;

      if (currentState != BluetoothConnectionState.connected) {
        await scanResult.device.connect(autoConnect: false);
        logger.d("Device connection initiated");
      }

      // Re-check connection status after connect
      BluetoothConnectionState connectionState =
          await scanResult.device.connectionState.first;

      if (connectionState == BluetoothConnectionState.connected) {
        logger.d("Device connected");
        toast.showToast('Device connected successfully.');

        final writeState =
            WriteState(device: scanResult.device, manager: manager);
        final result = await writeState.process();

        // Do NOT disconnect again here; WriteState handles it
        return result;
      } else {
        throw Exception("Failed to connect to the device.");
      }
    } catch (e) {
      toast.showErrorToast('Failed to connect, retrying...');
      logger.e("BLE connection error: $e");
      rethrow;
    }
  }
}
