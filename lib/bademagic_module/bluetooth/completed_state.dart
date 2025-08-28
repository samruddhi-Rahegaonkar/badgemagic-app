import 'package:badgemagic/bademagic_module/bluetooth/base_ble_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';

class CompletedState extends NormalBleState {
  final bool isSuccess;
  final String message;
  final TransferMode? mode;
  final bool shouldDisconnect;
  final DataTransferManager? manager;

  CompletedState({
    required this.isSuccess,
    required this.message,
    this.mode,
    this.shouldDisconnect = false,
    this.manager,
  });

  @override
  Future<BleState?> processState() async {
    if (shouldDisconnect && manager?.connectedDevice != null) {
      try {
        logger.d("Disconnecting device as requested...");

        if (mode == TransferMode.streaming && manager!.isStreamingActive) {
          await manager!.exitStreamingMode();
          await Future.delayed(const Duration(milliseconds: 200));
        }

        await manager!.connectedDevice!.disconnect();
        await Future.delayed(const Duration(milliseconds: 700));
        manager!.clearConnectedDevice();

        logger.d("Device disconnected successfully");
      } catch (e) {
        logger.e("Error during disconnection: $e");
      }
    }
    if (isSuccess) {
      toast.showToast(message);
    } else {
      toast.showErrorToast(message);
    }

    return null;
  }
}
