import 'package:badgemagic/bademagic_module/bluetooth/completed_state.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:logger/logger.dart';

abstract class BleState {
  Future<BleState?> process();
}

abstract class NormalBleState extends BleState {
  final logger = Logger();
  final toast = ToastUtils();

  Future<BleState?> processState();

  @override
  Future<BleState?> process() async {
    try {
      return await processState();
    } on Exception catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      logger.e("BLE state failed: $errorMessage");
      return CompletedState(isSuccess: false, message: errorMessage);
    }
  }
}

abstract class RetryBleState extends BleState {
  final logger = Logger();
  final toast = ToastUtils();

  final int _maxRetries = 3;

  Future<BleState?> processState();

  @override
  Future<BleState?> process() async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < _maxRetries) {
      try {
        return await processState();
      } on Exception catch (e) {
        logger.e("BLE retry attempt ${attempt + 1} failed: $e");
        lastException = e;
        attempt++;

        if (attempt < _maxRetries) {
          logger.d("Retrying BLE state ($attempt/$_maxRetries)...");
          await Future.delayed(Duration(seconds: 1));
        } else {
          logger.e("Max retries reached. Last exception: $lastException");
        }
      }
    }

    return CompletedState(
      isSuccess: false,
      message: lastException?.toString().replaceFirst('Exception: ', '') ??
          "Unknown error",
    );
  }
}
