import 'package:badgemagic/bademagic_module/bluetooth/base_ble_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';

class CompletedState extends NormalBleState {
  final bool isSuccess;
  final String message;
  final TransferMode? mode;
  final bool shouldDisconnect;

  CompletedState({
    required this.isSuccess,
    required this.message,
    this.mode,
    this.shouldDisconnect = false,
  });

  @override
  Future<BleState?> processState() async {
    if (isSuccess) {
      toast.showToast(message);
    } else {
      toast.showErrorToast(message);
    }

    return null;
  }
}
