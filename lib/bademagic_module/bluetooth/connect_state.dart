import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/bluetooth/write_state.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:badgemagic/providers/BadgeAliasProvider.dart';
import 'package:get_it/get_it.dart';
import 'base_ble_state.dart';

class ConnectState extends RetryBleState {
  final ScanResult scanResult;
  final DataTransferManager manager;
  final String displayName;

  ConnectState({
    required this.manager,
    required this.scanResult,
    required this.displayName,
  });

  @override
  Future<BleState?> processState() async {
    bool connected = false;

    try {
      await scanResult.device.connect(autoConnect: false);
      BluetoothConnectionState connectionState =
          await scanResult.device.connectionState.first;

      if (connectionState == BluetoothConnectionState.connected) {
        connected = true;

        String alias = displayName;
        final aliasProvider = GetIt.I<BadgeAliasProvider>();
        final maybeAlias = aliasProvider.getAlias(displayName);
        if (maybeAlias != null && maybeAlias.trim().isNotEmpty) {
          alias = maybeAlias;
        }

        logger.d("Device '$displayName' connected");
        toast.showToast('Connected successfully to "$alias".');

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
      toast.showErrorToast('Failed to connect to "$displayName", retrying...');
      rethrow;
    } finally {
      if (!connected) {
        await scanResult.device.disconnect();
      }
    }
  }
}
