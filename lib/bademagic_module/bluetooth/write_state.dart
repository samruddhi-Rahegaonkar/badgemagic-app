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
    List<List<int>> dataChunks = await manager.generateDataChunk();
    logger.d("Data to write: $dataChunks");
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid ==
                  Guid("0000fee1-0000-1000-8000-00805f9b34fb") &&
              characteristic.properties.write) {
            for (List<int> chunk in dataChunks) {
              bool success = false;
              for (int attempt = 1; attempt <= 3; attempt++) {
                try {
                  await characteristic.write(chunk, withoutResponse: false);
                  success = true;
                  break;
                } catch (e) {
                  logger.e("Write failed, retrying ([36m$attempt/3[0m): $e");
                }
              }
              if (!success) {
                throw Exception("Failed to transfer data. Please try again.");
              }
            }
            logger.d("Characteristic written successfully");
            return CompletedState(
                isSuccess: true, message: "Data transferred successfully");
          }
        }
      }
      throw Exception("Please use the correct Badge");
    } catch (e) {
      logger.e("Failed to write characteristic: $e");
      throw Exception("Failed to transfer data. Please try again.");
    } finally {
      try {
        await device.disconnect();
        logger.d("Device disconnected after write");
        await Future.delayed(const Duration(seconds: 1));
        logger.d("Waited 1s after disconnect");
      } catch (e) {
        logger.e("Error during disconnect: $e");
      }
    }
  }
}
