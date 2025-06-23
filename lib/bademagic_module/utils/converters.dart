import 'dart:math';

import 'package:badgemagic/bademagic_module/models/screen_size.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/data_to_bytearray_converter.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/image_utils.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:get_it/get_it.dart';

class Converters {
  final controllerData = GetIt.instance.get<InlineImageProvider>();
  final converter = DataToByteArrayConverter();
  final imageUtils = ImageUtils();
  final fileHelper = FileHelper();

  Future<List<String>> messageTohex(
    String message,
    bool isInverted,
    int rows,
    ScreenSize screenSize, {
    bool scale = true,
  }) async {
    List<String> hexStrings = [];

    for (int i = 0; i < message.length; i++) {
      if (_isEmojiTag(message, i)) {
        int index = int.parse(message.substring(i + 2, i + 4));
        hexStrings.addAll(await _handleEmoji(index, screenSize));
        i += 5;
      } else {
        hexStrings.addAll(_handleChar(message[i], screenSize, scale));
      }
    }

    if (isInverted) {
      hexStrings = padHexString(invertHex(hexStrings.join()).split(''), rows);
    }

    logger.d("Final hex strings count: ${hexStrings.length}");
    return hexStrings;
  }

  bool _isEmojiTag(String msg, int i) =>
      i + 5 < msg.length &&
      msg.substring(i, i + 2) == '<<' &&
      msg.substring(i + 4, i + 6) == '>>';

  Future<List<String>> _handleEmoji(int index, ScreenSize size) async {
    if (index >= controllerData.imageCache.length) {
      logger.e("Image cache index $index out of range");
      return [];
    }

    var key = controllerData.imageCache.keys.toList()[index];
    if (key is List) {
      final data = await fileHelper.readFromFile(key[0]);
      if (data == null) {
        logger.e("Failed to read file: ${key[0]}");
        return [];
      }

      var image = data.cast<List<dynamic>>().map((e) => e.cast<int>()).toList();
      var scaled = _scaleBitmapToBadgeSize(image, size.width, size.height);
      return convertBitmapToLEDHex(scaled, true);
    }

    if (index < controllerData.vectors.length) {
      return await imageUtils.generateLedHexWithSize(
          controllerData.vectors[index], size.width, size.height);
    }

    logger.e("Vector index $index out of range");
    return [];
  }

  List<String> _handleChar(String ch, ScreenSize size, bool scale) {
    if (!converter.charCodes.containsKey(ch)) {
      logger.w("Character '$ch' not found in charCodes");
      return [];
    }

    String hex = converter.charCodes[ch]!;

    if (!scale) {
      return [hex]; // ✅ return raw hex for test
    }

    var scaledBitmap = _scaleCharacterToBadgeSize(hex, size.width, size.height);
    return convertBitmapToLEDHex(scaledBitmap, true);
  }

  List<List<int>> _scaleCharacterToBadgeSize(
      String hex, int width, int height) {
    var bitmap = _hexStringToBitmap(hex);
    int scaledWidth = (width * 0.12).round().clamp(6, width ~/ 2);
    return _scaleTextCharacterToBadgeSize(bitmap, scaledWidth, height);
  }

  List<List<int>> _scaleTextCharacterToBadgeSize(
      List<List<int>> bitmap, int targetW, int targetH) {
    if (bitmap.isEmpty || bitmap[0].isEmpty) {
      return List.generate(targetH, (_) => List.filled(targetW, 0));
    }

    return List.generate(targetH, (y) {
      int srcY =
          (y * bitmap.length / targetH).floor().clamp(0, bitmap.length - 1);
      return List.generate(targetW, (x) {
        int srcX = (x * bitmap[0].length / targetW)
            .floor()
            .clamp(0, bitmap[0].length - 1);
        return bitmap[srcY][srcX];
      });
    });
  }

  List<List<int>> _hexStringToBitmap(String hex) {
    const int width = 8, height = 11;
    return List.generate(height, (row) {
      int byteVal = int.parse(hex.substring(row * 2, row * 2 + 2), radix: 16);
      return List.generate(width, (col) => (byteVal >> (7 - col)) & 1);
    });
  }

  List<List<int>> _scaleBitmapToBadgeSize(
      List<List<int>> original, int targetW, int targetH) {
    if (original.isEmpty || original[0].isEmpty) {
      return List.generate(targetH, (_) => List.filled(targetW, 0));
    }

    double scale = min(targetW / original[0].length, targetH / original.length);
    int scaledW = (original[0].length * scale).round();
    int scaledH = (original.length * scale).round();
    int offsetX = ((targetW - scaledW) / 2).floor();
    int offsetY = ((targetH - scaledH) / 2).floor();

    List<List<int>> result =
        List.generate(targetH, (_) => List.filled(targetW, 0));
    for (int y = 0; y < scaledH; y++) {
      for (int x = 0; x < scaledW; x++) {
        int sx = (x / scale).floor();
        int sy = (y / scale).floor();
        result[y + offsetY][x + offsetX] = original[sy][sx];
      }
    }
    return result;
  }

  static List<String> convertBitmapToLEDHex(List<List<int>> image, bool trim) {
    int height = image.length, width = image[0].length;
    int left = 0, right = 0;

    if (trim) {
      for (int j = 0; j < width; j++) {
        if (image.any((row) => row[j] == 1)) {
          left = j;
          break;
        }
      }
      for (int j = width - 1; j >= left; j--) {
        if (image.any((row) => row[j] == 1)) {
          right = width - j - 1;
          break;
        }
      }
    }

    int effectiveW = width - left - right;
    int paddedW = ((effectiveW + 7) ~/ 8) * 8;
    int padLeft = (paddedW - effectiveW) ~/ 2;

    return List.generate(paddedW ~/ 8, (block) {
      int colStart = block * 8;
      return List.generate(height, (row) {
        int byteVal = 0;
        for (int bit = 0; bit < 8; bit++) {
          int col = colStart + bit - padLeft + left;
          byteVal |=
              ((col >= 0 && col < width ? image[row][col] : 0) << (7 - bit));
        }
        return byteVal.toRadixString(16).padLeft(2, '0');
      }).join();
    });
  }

  static String invertHex(String hex) => hex
      .split('')
      .map((c) =>
          (~int.parse(c, radix: 16) & 0xF).toRadixString(16).toUpperCase())
      .join();

  List<String> padHexString(List<String> hex, int rows) {
    var boolGrid = hexStringToBool(hex.join(), rows)
        .map((row) => row.map((e) => e ? 1 : 0).toList())
        .toList();

    for (var row in boolGrid) {
      row.insert(0, 1);
      row.add(1);
    }

    return convertBitmapToLEDHex(boolGrid, true);
  }

  static List<List<bool>> textToBitmapFixedWidth(
    String msg,
    int height,
    DataToByteArrayConverter conv,
  ) {
    const int w = 8, h = 11, spacing = 2;
    if (msg.isEmpty) return List.generate(height, (_) => []);

    int totalWidth = msg.length * (w + spacing) - spacing;
    var bitmap = List.generate(height, (_) => List.filled(totalWidth, false));

    for (int i = 0; i < msg.length; i++) {
      var hex = conv.charCodes[msg[i]];
      if (hex == null) continue;

      var charBitmap = List.generate(h, (row) {
        int byte = int.parse(hex.substring(row * 2, row * 2 + 2), radix: 16);
        return List.generate(w, (col) => ((byte >> (7 - col)) & 1) == 1);
      });

      int offsetX = i * (w + spacing);
      for (int row = 0; row < height; row++) {
        int srcRow = ((row * h) / height).floor().clamp(0, h - 1);
        for (int col = 0; col < w; col++) {
          bitmap[row][offsetX + col] = charBitmap[srcRow][col];
        }
      }
    }

    return bitmap;
  }
}
