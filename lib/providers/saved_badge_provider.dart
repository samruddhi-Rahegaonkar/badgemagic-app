import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/badge_animation/animation_abstract.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

Map<int, Speed> speedMap = {
  1: Speed.one,
  2: Speed.two,
  3: Speed.three,
  4: Speed.four,
  5: Speed.five,
  6: Speed.six,
  7: Speed.seven,
  8: Speed.eight,
};

Map<int, Mode> modeValueMap = {
  0: Mode.left,
  1: Mode.right,
  2: Mode.up,
  3: Mode.down,
  4: Mode.fixed,
  5: Mode.animation,
  6: Mode.snowflake,
  7: Mode.picture,
  8: Mode.laser
};

class SavedBadgeProvider extends ChangeNotifier {
  static final Logger logger = Logger();
  Converters converters = Converters();
  FileHelper fileHelper = FileHelper();
  bool isSavedBadgeData = false;
  InlineImageProvider controllerData =
      GetIt.instance.get<InlineImageProvider>();

  void setIsSavedBadgeData(bool value) {
    isSavedBadgeData = value;
    notifyListeners();
  }

  void saveBadgeData(String filename, String message, bool isFlash,
      bool isMarquee, bool isInvert, int? speed, int animation) async {
    // Debug logging for save operation
    logger.i("=== SAVING BADGE DATA ===");
    logger.i("Filename: $filename");
    logger.i("Message: $message");
    logger.i("Animation Index: $animation");
    logger.i("Mode from modeValueMap[$animation]: ${modeValueMap[animation]}");
    logger.i("Speed: ${speedMap[speed]}");

    Data data = await getBadgeData(
      message,
      isFlash,
      isMarquee,
      isInvert,
      speedMap[speed] ?? Speed.one,
      modeValueMap[animation]!,
      animation,
    );

    // Debug the data object before saving
    logger.i("Data object to save: ${data.toJson()}");

    fileHelper.saveBadgeData(data, filename, isInvert);
    logger.i("=== BADGE DATA SAVED ===");
  }

  Future<Data> getBadgeData(String text, bool flash, bool marq, bool isInverted,
      Speed speed, Mode mode, int animationIndex) async {
    List<String> message = await converters.messageTohex(text, isInverted);

    // Debug logging for data creation
    logger.i("=== CREATING BADGE DATA ===");
    logger.i("Text: $text");
    logger.i("Animation Index: $animationIndex");
    logger.i("Mode: $mode");
    logger.i("Speed: $speed");
    logger.i("Converted message: $message");

    Data data = Data(messages: [
      Message(
        text: message,
        flash: flash,
        marquee: marq,
        speed: speed,
        mode: mode,
        animationIndex: animationIndex,
      )
    ]);

    // Verify the data was created correctly
    logger.i("Created data JSON: ${data.toJson()}");
    logger.i("Message animationIndex: ${data.messages.first.animationIndex}");

    return data;
  }

  void savedBadgeAnimation(
      Map<String, dynamic> data, AnimationBadgeProvider aniProvider) {
    logger.i("=== LOADING SAVED BADGE ANIMATION ===");
    logger.i("Raw data received: $data");

    final messageData = data['messages'][0];
    logger.i("Message data: $messageData");

    // Debug speed handling
    final speedHex = messageData['speed'];
    final speed = Speed.fromHex(speedHex);
    final speedInt = Speed.getIntValue(speed);
    logger.i("Speed hex: $speedHex, Speed enum: $speed, Speed int: $speedInt");

    aniProvider.calculateDuration(speedInt + 1);

    // Enhanced animation index handling with detailed logging
    int animationIndex;

    logger.i("Checking for animationIndex in messageData...");
    logger.i(
        "Contains animationIndex key: ${messageData.containsKey('animationIndex')}");

    if (messageData.containsKey('animationIndex')) {
      logger.i("animationIndex value: ${messageData['animationIndex']}");
      logger.i(
          "animationIndex is null: ${messageData['animationIndex'] == null}");
    }

    if (messageData.containsKey('animationIndex') &&
        messageData['animationIndex'] != null) {
      // Use the saved animationIndex if available
      animationIndex = messageData['animationIndex'];
      logger.i("✅ Using saved animationIndex: $animationIndex");
    } else {
      // Fallback to mode-based index
      final modeHex = messageData['mode'];
      final mode = Mode.fromHex(modeHex);
      animationIndex = Mode.getIntValue(mode);
      logger.w(
          "⚠️ Using mode-based animationIndex: $animationIndex for mode: $mode (hex: $modeHex)");
      logger.w("This might be the source of your issue!");
    }

    // Validate the animation index is within bounds
    if (animationIndex < 0 || animationIndex >= animationMap.length) {
      logger.e("❌ Invalid animation index: $animationIndex, defaulting to 0");
      animationIndex = 0;
    }

    // Debug animation mapping
    logger.i("Animation map length: ${animationMap.length}");
    logger.i("Available animations: ${animationMap.keys.toList()}");
    logger.i("Selected animation index: $animationIndex");

    // Set the animation mode
    BadgeAnimation? selectedAnimation = animationMap[animationIndex];
    if (selectedAnimation != null) {
      aniProvider.setAnimationMode(selectedAnimation);
      logger.i(
          "✅ Animation mode set to index: $animationIndex, animation: ${selectedAnimation.runtimeType}");
    } else {
      logger.e("❌ No animation found for index: $animationIndex");
      aniProvider
          .setAnimationMode(animationMap[0]); // Default to first animation
    }

    // Handle effects
    logger.i("=== SETTING EFFECTS ===");
    aniProvider.getCurrentEffect.clear(); // Clear existing effects first

    if (messageData['invert'] == true) {
      aniProvider.addEffect(effectMap[0]);
      logger.i("Added invert effect");
    }
    if (messageData['flash'] == true) {
      aniProvider.addEffect(effectMap[1]);
      logger.i("Added flash effect");
    }
    if (messageData['marquee'] == true) {
      aniProvider.addEffect(effectMap[2]);
      logger.i("Added marquee effect");
    }

    logger.i("Final effects set: ${aniProvider.getCurrentEffect}");

    // Process the text data
    String hexString = messageData['text'].join();
    List<List<bool>> binaryArray = hexStringToBool(hexString);
    aniProvider.setNewGrid(binaryArray);

    logger.i("=== SAVED BADGE ANIMATION LOADED ===");
  }

  bool getIsSavedBadgeData() => isSavedBadgeData;

  Map<String, dynamic> savedBadgeData = {};

  void setSavedBadgeDataMap(Map<String, dynamic> data) {
    logger.i("=== SETTING SAVED BADGE DATA MAP ===");
    logger.i("Data: $data");
    savedBadgeData = data;
    notifyListeners();
  }

  Map<String, dynamic> getSavedBadgeDataMap() => savedBadgeData;
}
