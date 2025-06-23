import 'package:badgemagic/bademagic_module/models/screen_size.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/providers/getitlocator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'Message to hex function should be able to generate the hex with skipping invalid characters',
      () async {
    setupLocator();
    Converters converters = Converters();
    const String message = "Hii!";
    const int badgeHeight = 11;
    const int badgeWidth = 44;
    List<String> result = await converters.messageTohex(
      message,
      false,
      badgeHeight,
      ScreenSize(width: badgeWidth, height: badgeHeight, name: ''),
    );
    List<String> expected = [
      "00666666667e6666666600", // 'H'
      "0010100030101010103800", // 'i'
      "0010100030101010103800", // 'i'
      "0010383838101000101000", // '!'
    ];

    expect(result, expected);
  });

  test('Converts a simple 2x2 bitmap to LED hex', () {
    List<List<int>> image = [
      [1, 0],
      [0, 1]
    ];

    List<String> result = Converters.convertBitmapToLEDHex(image, true);

    expect(result, ["1008"]);
  });
}
