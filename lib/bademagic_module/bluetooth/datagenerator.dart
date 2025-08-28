import 'dart:async';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/utils/data_to_bytearray_converter.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

enum TransferMode { legacy, streaming }

class DataTransferManager {
  final Data? data;
  TransferMode mode;

  BluetoothDevice? connectedDevice;

  BluetoothCharacteristic? legacyWriteCharacteristic;

  BluetoothCharacteristic? streamingWriteCharacteristic;
  BluetoothCharacteristic? streamingNotifyCharacteristic;
  StreamSubscription<List<int>>? notificationSubscription;

  final BadgeMessageProvider badgeData = BadgeMessageProvider();
  final DataToByteArrayConverter converter = DataToByteArrayConverter();
  final FileHelper fileHelper = FileHelper();
  final InlineImageProvider controllerData =
      GetIt.instance<InlineImageProvider>();
  final Converters _converters = Converters();
  final Logger logger = Logger();

  bool isStreamingActive = false;

  Map<String, dynamic>? _pendingStreamData;
  bool _isStreamingReady = false;

  DataTransferManager(this.data, {this.mode = TransferMode.legacy});

  factory DataTransferManager.forLegacy(Data data) =>
      DataTransferManager(data, mode: TransferMode.legacy);
  factory DataTransferManager.forStreaming() =>
      DataTransferManager(null, mode: TransferMode.streaming);

  void setPendingStreamData(Map<String, dynamic> streamData) {
    _pendingStreamData = streamData;
    logger.d("Stored pending stream data: ${streamData.keys}");
  }

  Map<String, dynamic> getPendingStreamData() {
    return _pendingStreamData ?? {};
  }

  bool isStreamingConnectionReady() {
    return _isStreamingReady &&
        connectedDevice != null &&
        streamingWriteCharacteristic != null &&
        isStreamingActive;
  }

  void setStreamingReady(bool ready) {
    _isStreamingReady = ready;
    logger.d("Streaming ready state: $ready");
  }

  Future<bool> processStreamingContent() async {
    if (_pendingStreamData == null) {
      logger.e("No pending stream data");
      return false;
    }

    try {
      Map<String, dynamic> params = _pendingStreamData!;
      logger.i("Processing streaming content: '${params['text']}'");

      String text = params['text'] ?? "";
      if (text.isEmpty) {
        logger.w("Empty text for streaming");
        return false;
      }

      List<String> hexStrings =
          await _converters.messageTohex(text, params['isInverted'] ?? false);

      if (hexStrings.isEmpty) {
        logger.w("No hex data generated for streaming");
        return false;
      }

      logger.d("Generated ${hexStrings.length} hex strings for streaming");

      List<List<bool>> bitmap = hexStringToBool(hexStrings.join());

      List<int> columns = convertBitmapToColumns(bitmap);

      logger.i("Streaming ${columns.length} columns");

      bool success = await streamBitmap(columns);

      _pendingStreamData = null;

      return success;
    } catch (e) {
      logger.e("Error processing streaming content: $e");
      return false;
    }
  }

  Future<List<List<int>>> generateDataChunk() async {
    if (data == null) throw Exception("No data provided for legacy transfer");
    return converter.convert(data!);
  }

  void clearConnectedDevice() {
    connectedDevice = null;
    legacyWriteCharacteristic = null;
    streamingWriteCharacteristic = null;
    streamingNotifyCharacteristic = null;
    notificationSubscription?.cancel();
    notificationSubscription = null;
    isStreamingActive = false;
    _isStreamingReady = false;
    _pendingStreamData = null;
  }

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

  Future<bool> streamBitmap(List<int> bitmap) async {
    if (!isStreamingActive || streamingWriteCharacteristic == null) {
      logger.e("Streaming not active or characteristic unavailable");
      return false;
    }

    try {
      logger.i("Streaming bitmap with ${bitmap.length} columns");

      List<int> command = [0x03];

      for (int column in bitmap) {
        command.add(column & 0xFF);
        command.add((column >> 8) & 0xFF);
      }

      logger.d("Sending ${command.length} bytes to streaming characteristic");

      await streamingWriteCharacteristic!
          .write(command, withoutResponse: false);

      await Future.delayed(const Duration(milliseconds: 200));

      logger.i("Bitmap streamed successfully, ${bitmap.length} columns");
      return true;
    } catch (e) {
      logger.e("Failed to stream bitmap: $e");
      return false;
    }
  }

  Future<bool> enterStreamingMode() async {
    if (streamingWriteCharacteristic == null) {
      logger.e("Streaming write characteristic not available");
      return false;
    }

    try {
      logger.i("Entering streaming mode...");

      List<int> command = [0x02, 0x00];
      await streamingWriteCharacteristic!
          .write(command, withoutResponse: false);

      await Future.delayed(const Duration(milliseconds: 200));

      isStreamingActive = true;
      logger.i("Successfully entered streaming mode");
      return true;
    } catch (e) {
      logger.e("Failed to enter streaming mode: $e");
      return false;
    }
  }

  Future<bool> exitStreamingMode() async {
    if (streamingWriteCharacteristic == null) return false;

    try {
      logger.i("Exiting streaming mode...");

      List<int> command = [0x02, 0x01];
      await streamingWriteCharacteristic!
          .write(command, withoutResponse: false);

      await Future.delayed(const Duration(milliseconds: 100));

      isStreamingActive = false;
      _isStreamingReady = false;

      logger.i("Successfully exited streaming mode");
      return true;
    } catch (e) {
      logger.e("Failed to exit streaming mode: $e");
      return false;
    }
  }

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
