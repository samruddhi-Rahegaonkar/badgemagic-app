import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'base_ble_state.dart';
import 'completed_state.dart';

class WriteState extends NormalBleState {
  final BluetoothDevice device;
  final DataTransferManager manager;

  WriteState({required this.manager, required this.device});

  @override
  Future<BleState?> processState() async {
    try {
      List<BluetoothService> services = await device.discoverServices();

      if (manager.mode == TransferMode.streaming) {
        return await _handleStreamingMode(services);
      } else {
        return await _handleLegacyMode(services);
      }
    } catch (e) {
      logger.e("Failed to process write state: $e");
      throw Exception("Failed to transfer data. Please try again.");
    }
  }

  Future<BleState?> _handleLegacyMode(List<BluetoothService> services) async {
    List<List<int>> dataChunks = await manager.generateDataChunk();
    logger.d("Legacy data to write: $dataChunks");

    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid ==
                Guid("0000fee1-0000-1000-8000-00805f9b34fb") &&
            characteristic.properties.write) {
          manager.legacyWriteCharacteristic = characteristic;

          for (List<int> chunk in dataChunks) {
            bool success = false;
            for (int attempt = 1; attempt <= 3; attempt++) {
              try {
                await characteristic.write(chunk, withoutResponse: false);
                logger.d("Legacy chunk written successfully: $chunk");
                success = true;
                break;
              } catch (e) {
                logger.e("Legacy write failed (attempt $attempt/3): $e");
              }
            }

            if (!success) {
              throw Exception("Failed to transfer data. Please try again.");
            }

            await Future.delayed(const Duration(milliseconds: 50));
          }

          logger.d("Legacy characteristic written successfully");
          return CompletedState(
            isSuccess: true,
            message: "Data transferred successfully",
            mode: TransferMode.legacy,
            shouldDisconnect: true, // ✅ disconnect after legacy
          );
        }
      }
    }

    throw Exception("Please use the correct Badge");
  }

  Future<BleState?> _handleStreamingMode(
      List<BluetoothService> services) async {
    BluetoothService? streamingService = _findStreamingService(services);

    if (streamingService != null) {
      return await _setupStreamingService(streamingService);
    } else {
      logger.d("Next-gen service not found, falling back to legacy mode");
      manager.mode = TransferMode.legacy;
      return await _handleLegacyMode(services);
    }
  }

  BluetoothService? _findStreamingService(List<BluetoothService> services) {
    return services.cast<BluetoothService?>().firstWhere(
          (service) =>
              service?.uuid == Guid("0000f055-0000-1000-8000-00805f9b34fb"),
          orElse: () => null,
        );
  }

  Future<BleState?> _setupStreamingService(BluetoothService service) async {
    BluetoothCharacteristic? writeChar;
    BluetoothCharacteristic? notifyChar;

    for (BluetoothCharacteristic char in service.characteristics) {
      if (char.uuid == Guid("0000f057-0000-1000-8000-00805f9b34fb") &&
          char.properties.write) {
        writeChar = char;
      } else if (char.uuid == Guid("0000f056-0000-1000-8000-00805f9b34fb") &&
          char.properties.notify) {
        notifyChar = char;
      }
    }

    if (writeChar == null) {
      throw Exception("Streaming write characteristic not found");
    }

    manager.streamingWriteCharacteristic = writeChar;

    if (notifyChar != null) {
      manager.streamingNotifyCharacteristic = notifyChar;
      await notifyChar.setNotifyValue(true);

      manager.notificationSubscription = notifyChar.lastValueStream.listen(
        (value) {
          if (value.isNotEmpty) {
            manager.handleStreamingErrorCode(value[0]);
          }
        },
        onError: (error) => logger.e("Notification error: $error"),
      );
    }

    bool success = await manager.enterStreamingMode();

    if (success) {
      logger.d("Streaming mode activated successfully");
      return CompletedState(
        isSuccess: true,
        message: "Streaming mode activated. Ready to stream bitmaps.",
        mode: TransferMode.streaming,
        shouldDisconnect: false, // ✅ stay connected for streaming
      );
    } else {
      throw Exception("Failed to activate streaming mode");
    }
  }
}
