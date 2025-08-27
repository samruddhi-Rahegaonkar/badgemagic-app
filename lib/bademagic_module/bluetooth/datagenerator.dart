// Enhanced DataTransferManager with streaming support
import 'dart:async';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/utils/data_to_bytearray_converter.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

enum TransferMode { legacy, streaming }

class DataTransferManager {
  final Data? data; // Make nullable for streaming-only usage
  TransferMode mode;

  BluetoothDevice? connectedDevice;

  // Legacy characteristics
  BluetoothCharacteristic? legacyWriteCharacteristic;

  // Streaming characteristics
  BluetoothCharacteristic? streamingWriteCharacteristic;
  BluetoothCharacteristic? streamingNotifyCharacteristic;
  StreamSubscription<List<int>>? notificationSubscription;

  final BadgeMessageProvider badgeData = BadgeMessageProvider();
  final DataToByteArrayConverter converter = DataToByteArrayConverter();
  final FileHelper fileHelper = FileHelper();
  final InlineImageProvider controllerData =
      GetIt.instance<InlineImageProvider>();
  final Logger logger = Logger();

  bool isStreamingActive = false;

  DataTransferManager(this.data, {this.mode = TransferMode.legacy});

  // Factory constructors for convenience
  factory DataTransferManager.forLegacy(Data data) =>
      DataTransferManager(data, mode: TransferMode.legacy);

  factory DataTransferManager.forStreaming(Data data) =>
      DataTransferManager(null, mode: TransferMode.streaming);

  Future<List<List<int>>> generateDataChunk() async {
    if (data == null) throw Exception("No data provided for legacy transfer");
    return converter.convert(data!);
  }

  /// Clear the currently connected device and cleanup
  void clearConnectedDevice() {
    connectedDevice = null;
    legacyWriteCharacteristic = null;
    streamingWriteCharacteristic = null;
    streamingNotifyCharacteristic = null;
    notificationSubscription?.cancel();
    notificationSubscription = null;
    isStreamingActive = false;
  }

  /// Handle error codes from streaming badge
  void handleStreamingErrorCode(int errorCode) {
    switch (errorCode) {
      case 0x00:
        logger.d("Streaming command executed successfully");
        break;
      case 0xff:
        logger.e("Streaming parameters out of range");
        break;
      case 0xfe:
        logger.e("Height larger than maximum allowed");
        break;
      case 0xfd:
        logger.e("Message length not matched");
        break;
      case 0xfc:
        logger.e("Missing pixel contents");
        break;
      case 0x01:
        logger.e("Flash writing error");
        break;
      case 0x02:
        logger.e("Speed/brightness out of range");
        break;
      default:
        logger.e("Unknown streaming error code: $errorCode");
    }
  }

  /// Stream bitmap data (for streaming mode)
  Future<bool> streamBitmap(List<int> bitmap) async {
    if (!isStreamingActive || streamingWriteCharacteristic == null) {
      logger.e("Streaming not active or characteristic unavailable");
      return false;
    }

    try {
      List<int> command = [0x03]; // stream_bitmap function code

      // Convert bitmap to 16-bit words (little-endian)
      for (int column in bitmap) {
        command.add(column & 0xFF);
        command.add((column >> 8) & 0xFF);
      }

      await streamingWriteCharacteristic!
          .write(command, withoutResponse: false);
      logger.d("Bitmap streamed successfully, ${bitmap.length} columns");
      return true;
    } catch (e) {
      logger.e("Failed to stream bitmap: $e");
      return false;
    }
  }

  /// Enter streaming mode
  Future<bool> enterStreamingMode() async {
    if (streamingWriteCharacteristic == null) return false;

    try {
      List<int> command = [0x02, 0x00]; // Enter streaming mode
      await streamingWriteCharacteristic!
          .write(command, withoutResponse: false);
      await Future.delayed(const Duration(milliseconds: 100));
      isStreamingActive = true;
      return true;
    } catch (e) {
      logger.e("Failed to enter streaming mode: $e");
      return false;
    }
  }

  /// Exit streaming mode
  Future<bool> exitStreamingMode() async {
    if (streamingWriteCharacteristic == null) return false;

    try {
      List<int> command = [0x02, 0x01]; // Exit streaming mode
      await streamingWriteCharacteristic!
          .write(command, withoutResponse: false);
      isStreamingActive = false;
      return true;
    } catch (e) {
      logger.e("Failed to exit streaming mode: $e");
      return false;
    }
  }

  /// Convert 2D bitmap to column format for streaming
  List<int> convertBitmapToColumns(List<List<bool>> bitmap) {
    if (bitmap.isEmpty) return [];

    int height = bitmap.length;
    int width = bitmap[0].length;
    List<int> columns = [];

    for (int col = 0; col < width; col++) {
      int columnValue = 0;
      for (int row = 0; row < height && row < 16; row++) {
        if (bitmap[row][col]) {
          columnValue |= (1 << row);
        }
      }
      columns.add(columnValue);
    }

    return columns;
  }
}
