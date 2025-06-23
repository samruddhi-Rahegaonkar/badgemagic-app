import 'dart:async';
import 'package:badgemagic/bademagic_module/models/screen_size.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/badge_animation/ani_animation.dart';
import 'package:badgemagic/badge_animation/ani_down.dart';
import 'package:badgemagic/badge_animation/ani_fixed.dart';
import 'package:badgemagic/badge_animation/ani_laser.dart';
import 'package:badgemagic/badge_animation/ani_left.dart';
import 'package:badgemagic/badge_animation/ani_picture.dart';
import 'package:badgemagic/badge_animation/ani_right.dart';
import 'package:badgemagic/badge_animation/ani_snowflake.dart';
import 'package:badgemagic/badge_animation/ani_up.dart';
import 'package:badgemagic/badge_animation/animation_abstract.dart';
import 'package:badgemagic/badge_effect/badgeeffectabstract.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/constants.dart';
import 'package:flutter/material.dart';

Map<int, BadgeAnimation?> animationMap = {
  0: LeftAnimation(),
  1: RightAnimation(),
  2: UpAnimation(),
  3: DownAnimation(),
  4: FixedAnimation(),
  5: SnowFlakeAnimation(),
  6: PictureAnimation(),
  7: AniAnimation(),
  8: LaserAnimation(),
};

Map<int, BadgeEffect> effectMap = {
  0: InvertLEDEffect(),
  1: FlashEffect(),
  2: MarqueeEffect(),
};

enum EffectType { flash, invert, marquee }

class AnimationBadgeProvider extends ChangeNotifier {
  int _animationIndex = 0;
  int _animationSpeed = aniSpeedStrategy(0);
  Timer? _timer;

  List<List<bool>> _paintGrid = [];
  List<List<bool>> _newGrid = [];
  final List<List<List<bool>>> _frames = [];
  int _currentFrame = 0;

  BadgeAnimation _currentAnimation = LeftAnimation();
  final Set<BadgeEffect?> _currentEffect = {};

  List<List<bool>> getPaintGrid() => _paintGrid;
  List<List<bool>> getNewGrid() => _newGrid;

  void initGrids(ScreenSize size) {
    _paintGrid = List.generate(
        size.height, (_) => List.generate(size.width, (_) => false));
    _newGrid = List.generate(
        size.height, (_) => List.generate(size.width, (_) => false));
    notifyListeners();
  }

  void setNewGrid(List<List<bool>> grid) {
    _newGrid = grid;
    _animationIndex = 0;
    notifyListeners();
  }

  Set<BadgeEffect?> get getCurrentEffect => _currentEffect;

  void addEffect(BadgeEffect? effect) {
    _currentEffect.add(effect);
    logger.i("Effect Added: $effect : $_currentEffect");
    notifyListeners();
  }

  void removeEffect(BadgeEffect? effect) {
    _currentEffect.remove(effect);
    notifyListeners();
  }

  bool isEffectActive(BadgeEffect? effect) {
    return _currentEffect.contains(effect);
  }

  void initializeAnimation() {
    if (_timer == null || !_timer!.isActive) {
      startTimer();
    }
  }

  void stopAnimation() {
    logger.d("Timer stopped  ${_timer?.tick.toString()}");
    _timer?.cancel();
    _animationIndex = 0;
  }

  void stopAllAnimations() {
    stopAnimation();
    _currentAnimation = LeftAnimation();
    _paintGrid = [];
    _newGrid = [];
    logger.d("All animations stopped");
  }

  void startTimer() {
    if (_newGrid.isEmpty || _newGrid[0].isEmpty) {
      logger.w("Cannot start animation timer: _newGrid is empty");
      return;
    }

    _timer =
        Timer.periodic(Duration(microseconds: _animationSpeed), (Timer timer) {
      renderGrid(getNewGrid());
      _animationIndex++;
    });
  }

  void setAnimationMode(BadgeAnimation? animation) {
    _animationIndex = 0;
    _currentAnimation = animation ?? LeftAnimation();
    notifyListeners();
    logger.i("Animation Mode set to: $_currentAnimation");
  }

  int? getAnimationIndex() {
    for (var animation in animationMap.entries) {
      if (animation.value != null && animation.value == _currentAnimation) {
        logger.i("Animation Index: ${animation.key}");
        return animation.key;
      }
    }
    return 0;
  }

  bool isAnimationActive(BadgeAnimation? badgeAnimation) {
    return _currentAnimation == badgeAnimation;
  }

  void badgeAnimation(
    String message,
    Converters converters,
    bool isInverted,
    ScreenSize screenSize,
  ) async {
    initGrids(screenSize);

    if (message.isEmpty) {
      stopAllAnimations();
      List<List<bool>> emptyGrid = List.generate(screenSize.height,
          (i) => List.generate(screenSize.width, (j) => false));
      _newGrid = emptyGrid;
      _paintGrid = emptyGrid;
      notifyListeners();
      return;
    }

    if (_timer == null || !_timer!.isActive) {
      startTimer();
    }

    List<List<bool>> fullBitmap;

    if (message.contains('<<') && message.contains('>>')) {
      List<String> hexStrings = await converters.messageTohex(
        message,
        isInverted,
        screenSize.height,
        screenSize,
      );

      fullBitmap = _hexStringsToBitmap(hexStrings, screenSize);
    } else {
      fullBitmap = Converters.textToBitmapFixedWidth(
        message,
        screenSize.height,
        converters.converter,
      );
    }

    setNewGrid(fullBitmap);
  }

  List<List<bool>> _hexStringsToBitmap(
      List<String> hexStrings, ScreenSize screenSize) {
    if (hexStrings.isEmpty) {
      return List.generate(screenSize.height,
          (_) => List.generate(screenSize.width, (_) => false));
    }

    int totalWidth = hexStrings.length * 8;

    List<List<bool>> bitmap = List.generate(
      screenSize.height,
      (_) => List.filled(totalWidth, false),
    );

    for (int hexIndex = 0; hexIndex < hexStrings.length; hexIndex++) {
      String hexString = hexStrings[hexIndex];

      int charsPerRow = 2;

      for (int row = 0;
          row < screenSize.height && row * charsPerRow < hexString.length;
          row++) {
        int byteStart = row * charsPerRow;
        int byteEnd = byteStart + charsPerRow;

        if (byteEnd <= hexString.length) {
          String rowHex = hexString.substring(byteStart, byteEnd);
          int byteVal = int.parse(rowHex, radix: 16);

          for (int bit = 0; bit < 8; bit++) {
            int col = hexIndex * 8 + bit;
            if (col < totalWidth) {
              bitmap[row][col] = ((byteVal >> (7 - bit)) & 1) == 1;
            }
          }
        }
      }
    }

    return bitmap;
  }

  void renderGrid(List<List<bool>> newGrid) {
    if (_paintGrid.isEmpty || _paintGrid[0].isEmpty) {
      logger.w("renderGrid skipped: _paintGrid is empty");
      return;
    }

    int badgeWidth = _paintGrid[0].length;
    int badgeHeight = _paintGrid.length;

    if (_frames.isNotEmpty) {
      _currentFrame = (_currentFrame + 1) % _frames.length;
      newGrid = _frames[_currentFrame];
    }

    var canvas = List.generate(
        badgeHeight, (i) => List.generate(badgeWidth, (j) => false));

    _currentAnimation.processAnimation(
        badgeHeight, badgeWidth, _animationIndex, newGrid, canvas);

    for (var effect in _currentEffect) {
      effect?.processEffect(_animationIndex, canvas, badgeHeight, badgeWidth);
    }

    _paintGrid = canvas;
    notifyListeners();
  }

  void calculateDuration(int speed) {
    int newSpeed = aniSpeedStrategy(speed - 1);
    if (newSpeed != _animationSpeed) {
      _animationSpeed = newSpeed;
      _timer?.cancel();
      startTimer();
    }
  }
}
