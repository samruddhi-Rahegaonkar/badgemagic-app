import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/bluetooth/write_state.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:badgemagic/providers/BadgeAliasProvider.dart';
import 'package:badgemagic/providers/getitlocator.dart'; // ⬅️ for getIt
import 'base_ble_state.dart';

class ConnectState extends RetryBleState {
  final ScanResult scanResult;
  final DataTransferManager manager;

  ConnectState({required this.manager, required this.scanResult});

  @override
  Future<BleState?> processState() async {
    bool connected = false;

    try {
      await scanResult.device.connect(autoConnect: false);
      BluetoothConnectionState connectionState =
          await scanResult.device.connectionState.first;

      if (connectionState == BluetoothConnectionState.connected) {
        connected = true;

        final aliasProvider = getIt<BadgeAliasProvider>();
        final deviceId = scanResult.device.id.id;
        final alias = aliasProvider.getAlias(deviceId);
        final nameToShow = (alias != null && alias.trim().isNotEmpty)
            ? alias
            : scanResult.device.name;

        logger.d("Device '$nameToShow' connected");
        toast.showToast('Device "$nameToShow" connected successfully.');

        final writeState =
            WriteState(device: scanResult.device, manager: manager);
        final result = await writeState.process();

        try {
          await scanResult.device.disconnect();
          logger.d("Device disconnected after transfer");
          await Future.delayed(const Duration(seconds: 1));
          logger.d("Waited 1s after disconnect");
        } catch (e) {
          logger.e("Error during disconnect after transfer: $e");
        }

        return result;
      } else {
        throw Exception("Failed to connect to the device");
      }
    } catch (e) {
      toast.showErrorToast('Failed to connect, retrying...');
      rethrow;
    } finally {
      if (!connected) {
        try {
          await scanResult.device.disconnect();
          logger.d("Device disconnected in finally block");
          await Future.delayed(const Duration(seconds: 1));
          logger.d("Waited 1s after disconnect (finally)");
        } catch (e) {
          logger.e("Error during disconnect in finally: $e");
        }
      }
    }
  }
}
