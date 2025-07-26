import 'dart:async';
import 'package:badgemagic/bademagic_module/bluetooth/connect_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/providers/BadgeScanProvider.dart';
import 'package:badgemagic/providers/BadgeAliasProvider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'base_ble_state.dart';

class ScanState extends NormalBleState {
  final DataTransferManager manager;
  final BadgeScanMode mode;
  final List<String> allowedNames;
  final BadgeAliasProvider aliasProvider;

  ScanState({
    required this.manager,
    required this.mode,
    required this.allowedNames,
    required this.aliasProvider,
  });

  @override
  Future<BleState?> processState() async {
    manager.clearConnectedDevice();
    await FlutterBluePlus.stopScan();

    toast.showToast("Searching for device...");
    Completer<BleState?> nextStateCompleter = Completer();
    StreamSubscription<List<ScanResult>>? subscription;

    bool isCompleted = false;
    bool stopScanCalled = false;

    void stopScanSafely() {
      if (!stopScanCalled) {
        stopScanCalled = true;
        FlutterBluePlus.stopScan();
      }
    }

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

                final matchesDirectName = mode == BadgeScanMode.any ||
                    normalizedAllowedNames.contains(deviceName);

                final aliasMatch = normalizedAllowedNames.any((realName) {
                  final alias =
                      aliasProvider.getAlias(realName)?.trim().toLowerCase();
                  return alias == deviceName;
                });

                return matchesUuid && (matchesDirectName || aliasMatch);
              },
              orElse: () => throw Exception("Matching device not found."),
            );

            isCompleted = true;
            stopScanSafely();

            toast.showToast('Device found. Connecting...');

            final foundName = foundDevice.device.name.trim();

            for (final real in allowedNames) {
              final alias = aliasProvider.getAlias(real)?.trim();
              if (alias != null &&
                  alias.toLowerCase() == foundName.toLowerCase()) {
                break;
              }
            }

            nextStateCompleter.complete(ConnectState(
              scanResult: foundDevice,
              manager: manager,
            ));
          } catch (e) {
            logger.w("No matching device found in this batch: $e");
          }
        },
        onError: (e) {
          if (!isCompleted) {
            isCompleted = true;
<<<<<<< HEAD
            FlutterBluePlus.stopScan();
=======
            stopScanSafely(); // ✅ Guarded again
>>>>>>> 5dbdbc0 (feat: Add Support for Renaming (Alias) BLE Devices in App)
            logger.e("Scan error: $e");
            toast.showErrorToast('Scan error occurred.');
            nextStateCompleter.completeError(Exception("Scan error: $e"));
          }
        },
      );
<<<<<<< HEAD
        timeout: const Duration(seconds: 15),
=======

      await FlutterBluePlus.startScan(
        withServices: [Guid("0000fee0-0000-1000-8000-00805f9b34fb")],
        removeIfGone: Duration(seconds: 5),
        continuousUpdates: true,
        timeout: const Duration(seconds: 15),
      );
>>>>>>> 5dbdbc0 (feat: Add Support for Renaming (Alias) BLE Devices in App)

      await Future.delayed(const Duration(seconds: 1));

      if (!isCompleted) {
        isCompleted = true;
<<<<<<< HEAD
        FlutterBluePlus.stopScan();
        toast.showErrorToast('Device not found.');
=======
        stopScanSafely();
        toast.showToast('Device not found.');
>>>>>>> 5dbdbc0 (feat: Add Support for Renaming (Alias) BLE Devices in App)
        nextStateCompleter.completeError(Exception('Device not found.'));
      }

      return await nextStateCompleter.future;
    } catch (e) {
      logger.e("Exception during scanning: $e");
      throw Exception("Please check if the device is turned on and retry.");
    } finally {
      await subscription?.cancel();
<<<<<<< HEAD
      await FlutterBluePlus.stopScan();
=======
      stopScanSafely();
>>>>>>> 5dbdbc0 (feat: Add Support for Renaming (Alias) BLE Devices in App)
    }
  }
}
