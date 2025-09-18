import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/bademagic_module/models/screen_size.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/data_to_bytearray_converter.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/image_utils.dart';
import 'package:badgemagic/providers/font_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';

String getFontKey(
    String fontFamily, double fontSize, FontWeight weight, bool italic) {
  return '$fontFamily-${fontSize.round()}-${weight.index}-$italic';
}

class Converters {
  final InlineImageProvider controllerData = GetIt.instance.get<InlineImageProvider>();
  final DataToByteArrayConverter converter = DataToByteArrayConverter();
  final ImageUtils imageUtils = ImageUtils();
  final FileHelper fileHelper = FileHelper();

  static final Map<String, List<List<bool>>> _characterCache = {};

  // --------------------- Public Methods ---------------------

  Future<List<String>> messageTohex(String message, bool isInverted) async {
    if (message.isEmpty) return [];

    final fontProvider = GetIt.instance<FontProvider>();
    final usingCustomFont = fontProvider.selectedFont != null;

    // Process message using either custom font or default
    List<String> hexStrings = usingCustomFont
        ? await _processCustomFontMessage(message, fontProvider.selectedTextStyle)
        : await _processDefaultFont(message);

    if (isInverted) {
      return _processInversion(hexStrings);
    }

    return hexStrings;
  }

  // --------------------- Private Helpers ---------------------

  Future<List<String>> _processDefaultFont(String text) async {
    List<Map<String, dynamic>> segments = [];
    String currentText = '';
    int i = 0;

    while (i < text.length) {
      if (text[i] == '<' && i + 5 < text.length && text[i + 5] == '>') {
        if (currentText.isNotEmpty) {
          segments.add({'type': 'text', 'content': currentText});
          currentText = '';
        }
        segments.add({'type': 'image', 'index': int.parse(text[i + 2] + text[i + 3])});
        i += 6;
      } else {
        currentText += text[i];
        i++;
      }
    }
    if (currentText.isNotEmpty) {
      segments.add({'type': 'text', 'content': currentText});
    }

    List<String> hexStrings = [];
    for (var segment in segments) {
      if (segment['type'] == 'text') {
        hexStrings.addAll(segment['content']
            .split('')
            .where((char) => converter.charCodes.containsKey(char))
            .map((char) => converter.charCodes[char]!)
            .toList());
      } else if (segment['type'] == 'image') {
        int index = segment['index'];
        var key = controllerData.imageCache.keys.toList()[index];
        if (key is List) {
          String filename = key[0];
          List<dynamic>? decodedData = await fileHelper.readFromFile(filename);
          final List<List<dynamic>> image = decodedData!.cast<List<dynamic>>();
          List<List<int>> imageData = image.map((list) => list.cast<int>()).toList();
          hexStrings.addAll(convertBitmapToLEDHex(imageData, true));
        } else {
          hexStrings.addAll(await imageUtils.generateLedHex(controllerData.vectors[index]));
        }
      }
    }

    return hexStrings;
  }

  Future<List<String>> _processCustomFontMessage(String text, TextStyle style) async {
    List<Map<String, dynamic>> segments = [];
    String currentText = '';
    int i = 0;

    while (i < text.length) {
      if (text[i] == '<' && i + 5 < text.length && text[i + 5] == '>') {
        if (currentText.isNotEmpty) {
          segments.add({'type': 'text', 'content': currentText});
          currentText = '';
        }
        segments.add({'type': 'image', 'index': int.parse(text[i + 2] + text[i + 3])});
        i += 6;
      } else {
        currentText += text[i];
        i++;
      }
    }
    if (currentText.isNotEmpty) {
      segments.add({'type': 'text', 'content': currentText});
    }

    List<List<bool>> combinedMatrix = List.generate(11, (_) => []);

    for (var segment in segments) {
      if (segment['type'] == 'text') {
        String text = segment['content'];
        for (int i = 0; i < text.length; i++) {
          String char = text[i];
          bool hasDescender = "ypgqj".contains(char);
          final matrixData = await renderTextToMatrix(char, style,
              rows: 11, hasDescender: hasDescender);
          List<List<bool>> charMatrix = matrixData['matrix'];
          for (int row = 0; row < 11; row++) {
            combinedMatrix[row].addAll(charMatrix[row]);
          }
        }
      } else if (segment['type'] == 'image') {
        int index = segment['index'];
        var key = controllerData.imageCache.keys.toList()[index];
        List<String> hexStrings;
        if (key is List) {
          String filename = key[0];
          List<dynamic>? decodedData = await fileHelper.readFromFile(filename);
          final List<List<dynamic>> image = decodedData!.cast<List<dynamic>>();
          List<List<int>> imageData = image.map((list) => list.cast<int>()).toList();
          hexStrings = convertBitmapToLEDHex(imageData, true);
        } else {
          hexStrings = await imageUtils.generateLedHex(controllerData.vectors[index]);
        }

        for (var hex in hexStrings) {
          for (int i = 0; i < 11; i++) {
            String hexByte = hex.substring(i * 2, (i * 2) + 2);
            int value = int.parse(hexByte, radix: 16);
            for (int bit = 0; bit < 8; bit++) {
              combinedMatrix[i].add(((value >> (7 - bit)) & 1) == 1);
            }
          }
        }
      }
    }

    // Pad to multiple of 8 columns
    int totalColumns = combinedMatrix.isNotEmpty ? combinedMatrix[0].length : 0;
    if (totalColumns % 8 != 0) {
      int paddingNeeded = 8 - (totalColumns % 8);
      final padding = List.filled(paddingNeeded, false);
      for (var row in combinedMatrix) {
        row.addAll(padding);
      }
    }

    List<String> allHexStrings = [];
    int segmentsCount = combinedMatrix.isNotEmpty ? combinedMatrix[0].length ~/ 8 : 0;

    for (int seg = 0; seg < segmentsCount; seg++) {
      final startCol = seg * 8;
      final endCol = startCol + 8;
      final segmentMatrix = List.generate(
          11, (row) => combinedMatrix[row].sublist(startCol, endCol));
      allHexStrings.addAll(_matrixToHex(segmentMatrix));
    }

    return allHexStrings;
  }

  Future<Map<String, dynamic>> renderTextToMatrix(
    String message,
    TextStyle textStyle, {
    int rows = 11,
    required bool hasDescender,
  }) async {
    final fontKey = getFontKey(
      textStyle.fontFamily ?? 'default',
      textStyle.fontSize ?? 14.0,
      textStyle.fontWeight ?? FontWeight.normal,
      textStyle.fontStyle == FontStyle.italic,
    );
    final cacheKey = '$fontKey-$message';

    if (_characterCache.containsKey(cacheKey)) {
      return {'matrix': _characterCache[cacheKey]!};
    }

    int cols = 1;
    int scale = 1;

    TextPainter widthCheckPainter = TextPainter(
      text: TextSpan(
        text: message,
        style: textStyle.copyWith(
            color: Colors.black, fontSize: (textStyle.fontSize ?? 14) * scale),
      ),
      textDirection: TextDirection.ltr,
    );
    widthCheckPainter.layout();
    final rawWidth = widthCheckPainter.width;
    cols = (rawWidth / scale).ceil().clamp(1, 16);

    final int width = cols * scale;
    final int height = rows * scale;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    final Paint bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bgPaint);

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: message,
        style: textStyle.copyWith(
            color: Colors.black, fontSize: (textStyle.fontSize ?? 14) * scale),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: width.toDouble());

    Offset offset = hasDescender
        ? Offset(0, height - 2 - textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic))
        : Offset(0, (height - 1) - textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic));

    textPainter.paint(canvas, offset);

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(width, height);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) throw Exception("Failed to convert image to byte data.");

    final Uint8List data = byteData.buffer.asUint8List();

    List<List<bool>> matrix = List.generate(rows, (_) => List.generate(cols, (_) => false));
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final int pixelIndex = (row * width + col) * 4;
        if (pixelIndex + 3 < data.length) {
          final int r = data[pixelIndex];
          final int g = data[pixelIndex + 1];
          final int b = data[pixelIndex + 2];
          final int brightness = ((r + g + b) / 3).round();
          matrix[row][col] = brightness < 128;
        }
      }
    }

    _characterCache[cacheKey] = matrix;
    return {'matrix': matrix};
  }

  List<String> _matrixToHex(List<List<bool>> matrix) {
    return List.generate(matrix.length, (i) {
      final binary = matrix[i].map((b) => b ? '1' : '0').join();
      return int.parse(binary, radix: 2).toRadixString(16).padLeft(2, '0');
    });
  }

  List<String> _processInversion(List<String> hexStrings) {
    final inverted = invertHex(hexStrings.join()).split('');
    return padHexString(inverted);
  }

  // --------------------- Bitmap / Hex Utilities ---------------------

  List<List<int>> _hexStringToBitmap(String hex) {
    const int width = 8, height = 11;
    return List.generate(height, (row) {
      int byteVal = int.parse(hex.substring(row * 2, row * 2 + 2), radix: 16);
      return List.generate(width, (col) => (byteVal >> (7 - col)) & 1);
    });
  }

  List<List<int>> _scaleTextCharacterToBadgeSize(
      List<List<int>> bitmap, int targetW, int targetH) {
    if (bitmap.isEmpty || bitmap[0].isEmpty) {
      return List.generate(targetH, (_) => List.filled(targetW, 0));
    }

    return List.generate(targetH, (y) {
      int srcY = (y * bitmap.length / targetH).floor().clamp(0, bitmap.length - 1);
      return List.generate(targetW, (x) {
        int srcX = (x * bitmap[0].length / targetW).floor().clamp(0, bitmap[0].length - 1);
        return bitmap[srcY][srcX];
      });
    });
  }

  List<List<int>> _scaleBitmapToBadgeSize(List<List<int>> original, int targetW, int targetH) {
    if (original.isEmpty || original[0].isEmpty) {
      return List.generate(targetH, (_) => List.filled(targetW, 0));
    }

    double scale = min(targetW / original[0].length, targetH / original.length);
    int scaledW = (original[0].length * scale).round();
    int scaledH = (original.length * scale).round();
    int offsetX = ((targetW - scaledW) / 2).floor();
    int offsetY = ((targetH - scaledH) / 2).floor();

    List<List<int>> result = List.generate(targetH, (_) => List.filled(targetW, 0));
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
          byteVal |= ((col >= 0 && col < width ? image[row][col] : 0) << (7 - bit));
        }
        return byteVal.toRadixString(16).padLeft(2, '0');
      }).join();
    });
  }

  static String invertHex(String hex) => hex
      .split('')
      .map((c) => (~int.parse(c, radix: 16) & 0xF).toRadixString(16).toUpperCase())
      .join();

  List<String> padHexString(List<String> hexArray, [int rows = 11]) {
    var boolGrid = hexStringToBool(hexArray.join(), rows)
        .map((row) => row.map((e) => e ? 1 : 0).toList())
        .toList();

    for (var row in boolGrid) {
      row.insert(0, 1);
      row.add(1);
    }

    return convertBitmapToLEDHex(boolGrid, true);
  }
}
