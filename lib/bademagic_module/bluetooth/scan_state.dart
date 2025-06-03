import 'dart:async';
import 'package:badgemagic/bademagic_module/bluetooth/connect_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/providers/BadgeScanProvider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'base_ble_state.dart';

class ScanState extends NormalBleState {
  final DataTransferManager manager;
  final BadgeScanMode mode;
  final List<String> allowedNames;

  ScanState({
    required this.manager,
    required this.mode,
    required this.allowedNames,
  });

  @override
  Future<BleState?> processState() async {
    StreamSubscription<List<ScanResult>>? subscription;
    toast.showToast("Searching for device...");

    final Completer<BleState?> nextStateCompleter = Completer();
    bool isCompleted = false;

    try {
      subscription = FlutterBluePlus.scanResults.listen(
        (results) async {
          if (isCompleted || results.isEmpty) return;

          try {
            final normalizedAllowedNames = allowedNames
                .map((e) => e.trim().toLowerCase())
                .where((e) => e.isNotEmpty)
                .toList();

            final foundDevice = results.firstWhere(
              (result) {
                final matchesUuid = result.advertisementData.serviceUuids
                    .contains(Guid("0000fee0-0000-1000-8000-00805f9b34fb"));

                final deviceName = result.device.name.trim().toLowerCase();
                final matchesName = mode == BadgeScanMode.any ||
                    normalizedAllowedNames.contains(deviceName);

                return matchesUuid && matchesName;
              },
              orElse: () => throw Exception("Matching device not found."),
            );

            isCompleted = true;
            FlutterBluePlus.stopScan();
            toast.showToast('Device found. Connecting...');

            nextStateCompleter.complete(ConnectState(
              scanResult: foundDevice,
              manager: manager,
            ));
          } catch (e) {
            logger.w("No matching device found in this batch: $e");
          }
        },
        onError: (e) async {
          if (!isCompleted) {
            isCompleted = true;
            logger.e("Scan error: $e");
            toast.showErrorToast('Scan error occurred.');
            nextStateCompleter.completeError(Exception("Scan error: $e"));
          }
        },
      );

      await FlutterBluePlus.startScan(
        withServices: [Guid("0000fee0-0000-1000-8000-00805f9b34fb")],
        removeIfGone: Duration(seconds: 5),
        continuousUpdates: true,
        timeout: const Duration(seconds: 15), // Reduced scan timeout
      );

      await Future.delayed(const Duration(seconds: 1));

      // If no device is found after the scan timeout, complete with an error.
      if (!isCompleted) {
        toast.showToast('Device not found.');
        nextStateCompleter.completeError(Exception('Device not found.'));
      }

      return await nextStateCompleter.future;
    } catch (e) {
      logger.e("Exception during scanning: $e");
      throw Exception("please check the device is turned on and retry.");
    } finally {
      await subscription?.cancel();
    }
  }
}
