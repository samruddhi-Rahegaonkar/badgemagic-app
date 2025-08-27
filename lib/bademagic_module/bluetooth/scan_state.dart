import 'dart:async';
import 'package:badgemagic/bademagic_module/bluetooth/connect_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'base_ble_state.dart';

class ScanState extends NormalBleState {
  final DataTransferManager manager;

  ScanState({required this.manager});

  @override
  Future<BleState?> processState() async {
    manager.clearConnectedDevice();
    await FlutterBluePlus.stopScan();

    String searchMessage = manager.mode == TransferMode.streaming
        ? "Searching for streaming device..."
        : "Searching for device...";
    toast.showToast(searchMessage);

    Completer<BleState?> nextStateCompleter = Completer();
    StreamSubscription<List<ScanResult>>? subscription;
    bool isCompleted = false;

    try {
      subscription = FlutterBluePlus.scanResults.listen(
        (results) async {
          if (isCompleted || results.isEmpty) return;

          try {
            final foundDevice = results.firstWhere(
              (r) => _deviceSupportsRequiredMode(r, manager.mode),
              orElse: () => throw Exception("Compatible device not found."),
            );

            isCompleted = true;
            await FlutterBluePlus.stopScan();

            String foundMessage = manager.mode == TransferMode.streaming
                ? 'Streaming device found. Connecting...'
                : 'Device found. Connecting...';
            toast.showToast(foundMessage);

            nextStateCompleter.complete(
              ConnectState(scanResult: foundDevice, manager: manager),
            );
          } catch (_) {
            // keep scanning until timeout
          }
        },
        onError: (e) {
          if (!isCompleted) {
            isCompleted = true;
            FlutterBluePlus.stopScan();
            logger.e("Scan error: $e");
            toast.showErrorToast('Scan error occurred.');
            nextStateCompleter.completeError(
              Exception("Error during scanning: $e"),
            );
          }
        },
      );

      // Start scan with proper services
      List<Guid> services = _getServicesForMode(manager.mode);
      await FlutterBluePlus.startScan(
        withServices: services,
        removeIfGone: const Duration(seconds: 5),
        continuousUpdates: true,
        timeout: const Duration(seconds: 15),
      );

      // Instead of 1s fixed delay, let the scan timeout handle completion
      return await nextStateCompleter.future;
    } catch (e) {
      logger.e("Exception during scanning: $e");
      throw Exception("Please check if the device is turned on and retry.");
    } finally {
      await subscription?.cancel();
      await FlutterBluePlus.stopScan();
    }
  }

  bool _deviceSupportsRequiredMode(ScanResult result, TransferMode mode) {
    List<Guid> serviceUuids = result.advertisementData.serviceUuids;

    switch (mode) {
      case TransferMode.legacy:
        return serviceUuids
            .contains(Guid("0000fee0-0000-1000-8000-00805f9b34fb"));
      case TransferMode.streaming:
        // Prefer next-gen service, fallback to legacy
        if (serviceUuids
            .contains(Guid("0000f055-0000-1000-8000-00805f9b34fb"))) {
          return true; // ✅ streaming
        }
        if (serviceUuids
            .contains(Guid("0000fee0-0000-1000-8000-00805f9b34fb"))) {
          logger.w("Streaming service not found, falling back to legacy.");
          manager.mode = TransferMode.legacy; // switch mode internally
          return true;
        }
        return false;
    }
  }

  List<Guid> _getServicesForMode(TransferMode mode) {
    switch (mode) {
      case TransferMode.legacy:
        return [Guid("0000fee0-0000-1000-8000-00805f9b34fb")];
      case TransferMode.streaming:
        return [
          Guid("0000f055-0000-1000-8000-00805f9b34fb"), // next-gen
          Guid("0000fee0-0000-1000-8000-00805f9b34fb"), // legacy fallback
        ];
    }
  }
}
