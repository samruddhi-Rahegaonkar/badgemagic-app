import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:badgemagic/bademagic_module/models/screen_size.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/data_to_bytearray_converter.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/image_utils.dart';
import 'package:badgemagic/providers/font_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

String getFontKey(
    String fontFamily, double fontSize, FontWeight weight, bool italic) {
  return '$fontFamily-${fontSize.round()}-${weight.index}-$italic';
}

class Converters {
  InlineImageProvider controllerData =
      GetIt.instance.get<InlineImageProvider>();
  DataToByteArrayConverter converter = DataToByteArrayConverter();
  ImageUtils imageUtils = ImageUtils();
  FileHelper fileHelper = FileHelper();
  final Logger logger = Logger();

  static final Map<String, List<List<bool>>> _characterCache = {};

  Future<List<String>> messageTohex(
      String message, bool isInverted, int rows, ScreenSize screenSize,
      {bool scale = true}) async {
    if (message.isEmpty) return [];

    final fontProvider = GetIt.instance<FontProvider>();
    final usingCustomFont = fontProvider.selectedFont != null;

    List<String> hexStrings = usingCustomFont
        ? await _processCustomFontMessage(
            message, fontProvider.selectedTextStyle, screenSize, scale)
        : await _processDefaultFont(message, screenSize, scale);

    if (isInverted) {
      return _processInversion(hexStrings, screenSize);
    }

    return hexStrings;
  }

  List<String> _matrixToHex(List<List<bool>> matrix) {
    return List.generate(matrix.length, (i) {
      final binary = matrix[i].map((b) => b ? '1' : '0').join();
      return int.parse(binary, radix: 2).toRadixString(16).padLeft(2, '0');
    });
  }

  Future<Map<String, dynamic>> renderTextToMatrix(
    String message,
    TextStyle textStyle, {
    required int targetWidth,
    required int targetHeight,
    required bool hasDescender, // for characters like j, g, p, q, y
  }) async {
    final fontKey = getFontKey(
      textStyle.fontFamily ?? 'default',
      textStyle.fontSize ?? 14.0,
      textStyle.fontWeight ?? FontWeight.normal,
      textStyle.fontStyle == FontStyle.italic,
    );
    final cacheKey = '$fontKey-$message-$targetWidth-$targetHeight';

    if (_characterCache.containsKey(cacheKey)) {
      return {
        'matrix': _characterCache[cacheKey]!,
      };
    }

    // Calculate font size to fit within target dimensions
    double fontSize = textStyle.fontSize ?? 14.0;
    TextPainter sizeCheckPainter = TextPainter(
      text: TextSpan(
          text: message, style: textStyle.copyWith(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    );
    sizeCheckPainter.layout();

    // Scale font size to fit target dimensions while maintaining aspect ratio
    double scaleX = targetWidth / sizeCheckPainter.width;
    double scaleY = targetHeight / sizeCheckPainter.height;
    double scale = min(scaleX, scaleY);

    fontSize = fontSize * scale;
    final scaledStyle = textStyle.copyWith(fontSize: fontSize);

    // Create final text painter with scaled font
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: message, style: scaledStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final int width = targetWidth;
    final int height = targetHeight;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
        recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    final Paint bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bgPaint);

    // Center the text in the canvas
    final double textWidth = textPainter.width;
    final double textHeight = textPainter.height;
    final double offsetX = (width - textWidth) / 2;
    final double offsetY = hasDescender
        ? (height - textHeight) - 2 // Leave space for descenders
        : (height - textHeight) / 2;

    textPainter.paint(canvas, Offset(offsetX, offsetY));

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(width, height);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) {
      throw Exception("Failed to convert image to byte data.");
    }
    final Uint8List data = byteData.buffer.asUint8List();

    List<List<bool>> matrix =
        List.generate(height, (_) => List.generate(width, (_) => false));
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
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

  Future<List<String>> _processCustomFontMessage(
      String text, TextStyle style, ScreenSize size, bool scale) async {
    try {
      List<Map<String, dynamic>> segments = [];
      String currentText = '';
      int i = 0;
      while (i < text.length) {
        if (text[i] == '<' && i + 5 < text.length && text[i + 5] == '>') {
          if (currentText.isNotEmpty) {
            segments.add({'type': 'text', 'content': currentText});
            currentText = '';
          }
          segments.add(
              {'type': 'image', 'index': int.parse(text[i + 2] + text[i + 3])});
          i += 6;
        } else {
          currentText += text[i];
          i++;
        }
      }
      if (currentText.isNotEmpty) {
        segments.add({'type': 'text', 'content': currentText});
      }

      List<List<bool>> combinedMatrix = List.generate(size.height, (_) => []);

      for (var segment in segments) {
        if (segment['type'] == 'text') {
          String text = segment['content'];
          for (int i = 0; i < text.length; i++) {
            String char = text[i];
            bool hasDescender = "ypgqj".contains(char);
            final matrixData = await renderTextToMatrix(char, style,
                targetWidth: size.width,
                targetHeight: size.height,
                hasDescender: hasDescender);
            List<List<bool>> charMatrix = matrixData['matrix'];
            for (int row = 0; row < size.height; row++) {
              combinedMatrix[row].addAll(charMatrix[row]);
            }
          }
        } else if (segment['type'] == 'image') {
          int index = segment['index'];
          var key = controllerData.imageCache.keys.toList()[index];
          List<String> hexStrings;
          if (key is List) {
            String filename = key[0];
            List<dynamic>? decodedData =
                await fileHelper.readFromFile(filename);
            final List<List<dynamic>> image =
                decodedData!.cast<List<dynamic>>();
            List<List<int>> imageData =
                image.map((list) => list.cast<int>()).toList();
            hexStrings = convertBitmapToLEDHex(imageData, true);
          } else {
            hexStrings = await imageUtils.generateLedHexWithSize(
                controllerData.vectors[index], size.width, size.height);
          }

          for (var hex in hexStrings) {
            for (int i = 0; i < size.height; i++) {
              String hexByte = hex.substring(i * 2, (i * 2) + 2);
              int value = int.parse(hexByte, radix: 16);
              for (int bit = 0; bit < 8; bit++) {
                combinedMatrix[i].add(((value >> (7 - bit)) & 1) == 1);
              }
            }
          }
        }
      }

      int totalColumns =
          combinedMatrix.isNotEmpty ? combinedMatrix[0].length : 0;
      if (totalColumns % 8 != 0) {
        int paddingNeeded = 8 - (totalColumns % 8);
        final padding = List.filled(paddingNeeded, false);
        for (var row in combinedMatrix) {
          row.addAll(padding);
        }
      }

      List<String> allHexStrings = [];
      int segmentsCount =
          combinedMatrix.isNotEmpty ? combinedMatrix[0].length ~/ 8 : 0;

      for (int seg = 0; seg < segmentsCount; seg++) {
        final startCol = seg * 8;
        final endCol = startCol + 8;
        final segmentMatrix = List.generate(size.height,
            (row) => combinedMatrix[row].sublist(startCol, endCol));

        final List<String> hexBytes = _matrixToHex(segmentMatrix);
        final String segmentHex = hexBytes.join();
        allHexStrings.add(segmentHex);
      }

      return allHexStrings;
    } catch (e, stacktrace) {
      logger.e("Error processing custom font message",
          error: e, stackTrace: stacktrace);
      return [];
    }
  }

  Future<List<String>> _processDefaultFont(
      String text, ScreenSize size, bool scale) async {
    List<Map<String, dynamic>> segments = [];
    String currentText = '';

    int i = 0;
    while (i < text.length) {
      if (text[i] == '<' && i + 5 < text.length && text[i + 5] == '>') {
        if (currentText.isNotEmpty) {
          segments.add({'type': 'text', 'content': currentText});
          currentText = '';
        }
        segments.add(
            {'type': 'image', 'index': int.parse(text[i + 2] + text[i + 3])});
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
        String text = segment['content'];
        for (int i = 0; i < text.length; i++) {
          String ch = text[i];
          if (!converter.charCodes.containsKey(ch)) continue;
          String hex = converter.charCodes[ch]!;

          if (!scale) {
            hexStrings.add(hex);
          } else {
            var scaledBitmap =
                _scaleCharacterToBadgeSize(hex, size.width, size.height);
            hexStrings.addAll(convertBitmapToLEDHex(scaledBitmap, true));
          }
        }
      } else if (segment['type'] == 'image') {
        int index = segment['index'];
        var key = controllerData.imageCache.keys.toList()[index];
        if (key is List) {
          String filename = key[0];
          List<dynamic>? decodedData = await fileHelper.readFromFile(filename);
          final List<List<dynamic>> image = decodedData!.cast<List<dynamic>>();
          List<List<int>> imageData =
              image.map((list) => list.cast<int>()).toList();
          hexStrings.addAll(convertBitmapToLEDHex(imageData, true));
        } else {
          hexStrings.addAll(await imageUtils.generateLedHexWithSize(
              controllerData.vectors[index], size.width, size.height));
        }
      }
    }
    return hexStrings;
  }

  List<String> _processInversion(
      List<String> hexStrings, ScreenSize screenSize) {
    final inverted = invertHex(hexStrings.join()).split('');
    return padHexString(inverted, screenSize);
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

  //function to convert the bitmap to the LED hex format
  //it takes the 2D list of pixels and converts it to the LED hex format
  static List<String> convertBitmapToLEDHex(List<List<int>> image, bool trim) {
    // Determine the height and width of the image
    int height = image.length;
    int width = image.isNotEmpty ? image[0].length : 0;

    // Initialize variables to calculate padding and offsets
    int finalSum = 0;

    // Calculate and adjust for right-side padding
    for (int j = 0; j < width; j++) {
      int sum = 0;
      for (int i = 0; i < height; i++) {
        sum += image[i][j]; // Sum up pixel values in each column
      }
      if (sum == 0 && trim) {
        // If column sum is zero, mark all pixels in that column as -1
        for (int i = 0; i < height; i++) {
          image[i][j] = -1;
        }
      } else {
        // Otherwise, update finalSum and exit loop
        finalSum += j;
        break;
      }
    }

    // Calculate and adjust for left-side padding
    for (int j = width - 1; j >= 0; j--) {
      int sum = 0;
      for (int i = 0; i < height; i++) {
        sum += image[i]
            [j]; // Sum up pixel values in each column (from right to left)
      }
      if (sum == 0 && trim) {
        // If column sum is zero, mark all pixels in that column as -1
        for (int i = 0; i < height; i++) {
          image[i][j] = -1;
        }
      } else {
        // Otherwise, update finalSum and exit loop
        finalSum += (height - j - 1);
        break;
      }
    }

    // Calculate padding difference to align height to a multiple of 8
    int diff = 0;
    if ((height - finalSum) % 8 > 0) {
      diff = 8 - (height - finalSum) % 8;
    }

    // Calculate left and right offsets for padding
    int rOff = (diff / 2).floor();
    int lOff = (diff / 2).ceil();

    // Initialize a new list to accommodate the padded image
    List<List<int>> list =
        List.generate(height, (i) => List.filled(width + rOff + lOff, 0));

    // Fill the new list with the padded image data
    for (int i = 0; i < height; i++) {
      int k = 0;
      for (int j = 0; j < rOff; j++) {
        list[i][k++] = 0; // Fill right-side padding
      }
      for (int j = 0; j < width; j++) {
        if (image[i][j] != -1) {
          list[i][k++] = image[i][j]; // Copy non-padded pixels
        }
      }
      for (int j = 0; j < lOff; j++) {
        list[i][k++] = 0; // Fill left-side padding
      }
    }

    //logger.d("Padded image: $list");

    // Convert each 8-bit segment into hexadecimal strings
    List<String> allHexs = [];
    for (int i = 0; i < list[0].length ~/ 8; i++) {
      StringBuffer lineHex = StringBuffer();

      for (int k = 0; k < height; k++) {
        StringBuffer stBuilder = StringBuffer();

        // Construct 8-bit segments for each row
        for (int j = i * 8; j < i * 8 + 8; j++) {
          stBuilder.write(list[k][j]);
        }

        // Convert binary string to hexadecimal
        String hex = int.parse(stBuilder.toString(), radix: 2)
            .toRadixString(16)
            .padLeft(2, '0');
        lineHex.write(hex); // Append hexadecimal to line
      }

      allHexs.add(lineHex.toString()); // Store completed hexadecimal line
    }
    return allHexs; // Return list of hexadecimal strings
  }

  static String invertHex(String hex) => hex
      .split('')
      .map((c) =>
          (~int.parse(c, radix: 16) & 0xF).toRadixString(16).toUpperCase())
      .join();

  List<String> padHexString(List<String> hex, ScreenSize screenSize) {
    var boolGrid = hexStringToBool(hex.join(), screenSize.height)
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
