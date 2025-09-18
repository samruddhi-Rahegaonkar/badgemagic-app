import 'dart:async';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
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
import 'package:badgemagic/badge_animation/ani_pacman.dart';
import 'package:badgemagic/badge_animation/ani_chevron_left.dart';
import 'package:badgemagic/badge_animation/ani_diamond.dart';
import 'package:badgemagic/badge_animation/ani_broken_hearts.dart';
import 'package:badgemagic/badge_animation/ani_cupid.dart';
import 'package:badgemagic/badge_animation/ani_feet.dart';
import 'package:badgemagic/badge_animation/ani_fish.dart';
import 'package:badgemagic/badge_animation/ani_diagonal.dart';
import 'package:badgemagic/badge_animation/ani_emergency.dart';
import 'package:badgemagic/badge_animation/ani_beating_hearts.dart';
import 'package:badgemagic/badge_animation/ani_fireworks.dart';
import 'package:badgemagic/badge_animation/ani_equalizer.dart'; // Equalizer
import 'package:badgemagic/badge_animation/ani_cycle.dart'; // Cycle
import 'package:badgemagic/badge_animation/animation_abstract.dart';
import 'package:badgemagic/badge_effect/badgeeffectabstract.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/constants.dart';
import 'package:flutter/material.dart';
import 'package:badgemagic/bademagic_module/models/screen_size.dart';

Map<int, BadgeAnimation?> animationMap = {
  0: LeftAnimation(),
  1: RightAnimation(),
  2: UpAnimation(),
  3: DownAnimation(),
  4: FixedAnimation(),
  5: AniAnimation(),
  6: SnowFlakeAnimation(),
  7: PictureAnimation(),
  8: LaserAnimation(),
  9: PacmanClassicAnimation(),
  10: LeftChevronAnimation(),
  11: DiamondAnimation(),
  12: BrokenHeartsAnimation(),
  13: CupidAnimation(),
  14: FeetAnimation(),
  15: FishAnimation(),
  16: DiagonalAnimation(),
  17: EmergencyAnimation(),
  18: BeatingHeartsAnimation(),
  19: FireworksAnimation(),
  20: EqualizerAnimation(),
  21: CycleAnimation(),
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
  bool _isDisposed = false;

  List<List<bool>> _paintGrid = [];
  List<List<bool>> _newGrid = [];
  final List<List<List<bool>>> _frames = [];
  int _currentFrame = 0;

  BadgeAnimation _currentAnimation = LeftAnimation();
  final Set<BadgeEffect?> _currentEffect = {};

  List<List<bool>> getPaintGrid() => _paintGrid;
  List<List<bool>> getNewGrid() => _newGrid;

  bool isSpecialAnimationSelected() {
    int idx = getAnimationIndex() ?? 0;
    return [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21].contains(idx);
  }

  void resetToTextAnimation() {
    setAnimationMode(LeftAnimation());
  }

  void calculateDuration(int speed) {
    if (_isDisposed) return;

    int idx = getAnimationIndex() ?? 0;
    int newSpeed;
    if ([9, 10, 11, 12, 20, 21].contains(idx)) {
      newSpeed = aniSpeedStrategy(speed - 1);
    } else {
      const int originalBase = 200000;
      const int minSpeed = 25000;
      newSpeed = originalBase - ((speed - 1) * (originalBase - minSpeed) ~/ 8);
    }
    if (newSpeed != _animationSpeed) {
      _animationSpeed = newSpeed;
      _timer?.cancel();
      startTimer();
    }
  }

  void initGrids(ScreenSize size) {
    if (_isDisposed) return;
    _paintGrid = List.generate(size.height, (_) => List.generate(size.width, (_) => false));
    _newGrid = List.generate(size.height, (_) => List.generate(size.width, (_) => false));
    notifyListeners();
  }

  void setNewGrid(List<List<bool>> grid) {
    if (_isDisposed) return;
    _newGrid = grid;
    _animationIndex = 0;
    notifyListeners();
  }

  Set<BadgeEffect?> get getCurrentEffect => _currentEffect;

  void clearAllEffects() {
    if (_isDisposed) return;
    _currentEffect.clear();
    notifyListeners();
  }

  void addEffect(BadgeEffect? effect) {
    if (_isDisposed) return;
    _currentEffect.add(effect);
    logger.i("Effect Added: $effect : $_currentEffect");
    notifyListeners();
  }

  void removeEffect(BadgeEffect? effect) {
    if (_isDisposed) return;
    _currentEffect.remove(effect);
    notifyListeners();
  }

  bool isEffectActive(BadgeEffect? effect) {
    return _currentEffect.contains(effect);
  }

  void initializeAnimation() {
    if (_isDisposed) return;
    if (_timer == null || !_timer!.isActive) startTimer();
  }

  void stopAnimation() {
    logger.d("Timer stopped  ${_timer?.tick.toString()}");
    _timer?.cancel();
    _timer = null;
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
    if (_isDisposed) return;
    if (_newGrid.isEmpty || _newGrid[0].isEmpty) {
      logger.w("Cannot start animation timer: _newGrid is empty");
      return;
    }
    _timer?.cancel();

    _timer = Timer.periodic(Duration(microseconds: _animationSpeed), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      renderGrid(getNewGrid());
      if (_currentAnimation is CupidAnimation) {
        int frameLimit = CupidAnimation.frameCount(_paintGrid[0].length, _paintGrid.length);
        _animationIndex = (_animationIndex + 1) % frameLimit;
      } else {
        _animationIndex++;
      }
    });
  }

  void setAnimationMode(BadgeAnimation? animation) {
    if (_isDisposed) return;
    _animationIndex = 0;
    _currentAnimation = animation ?? LeftAnimation();
    _timer?.cancel();
    startTimer();
    notifyListeners();
    logger.i("Animation Mode set to: $_currentAnimation and timer restarted");
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

  void badgeAnimation(String message, Converters converters, bool isInverted, ScreenSize screenSize) async {
    if (_isDisposed) return;

    bool isSpecial = isSpecialAnimationSelected();
    if (message.isEmpty && !isSpecial) {
      stopAllAnimations();
      List<List<bool>> emptyGrid = List.generate(screenSize.height, (i) => List.generate(screenSize.width, (j) => false));
      _newGrid = emptyGrid;
      _paintGrid = emptyGrid;
      notifyListeners();
      return;
    }

    if (_timer == null || !_timer!.isActive) startTimer();

    List<List<bool>> fullBitmap;

    if (message.contains('<<') && message.contains('>>')) {
      List<String> hexStrings = await converters.messageTohex(message, isInverted, screenSize.height, screenSize);
      fullBitmap = _hexStringsToBitmap(hexStrings, screenSize);
    } else {
      fullBitmap = Converters.textToBitmapFixedWidth(message, screenSize.height, converters.converter);
    }

    setNewGrid(fullBitmap);
  }

  List<List<bool>> _hexStringsToBitmap(List<String> hexStrings, ScreenSize screenSize) {
    if (hexStrings.isEmpty) {
      return List.generate(screenSize.height, (_) => List.generate(screenSize.width, (_) => false));
    }

    int totalWidth = hexStrings.length * 8;
    List<List<bool>> bitmap = List.generate(screenSize.height, (_) => List.filled(totalWidth, false));

    for (int hexIndex = 0; hexIndex < hexStrings.length; hexIndex++) {
      String hexString = hexStrings[hexIndex];
      int charsPerRow = 2;

      for (int row = 0; row < screenSize.height && row * charsPerRow < hexString.length; row++) {
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
    if (_isDisposed) return;
    if (_paintGrid.isEmpty || _paintGrid[0].isEmpty) return;

    int badgeWidth = _paintGrid[0].length;
    int badgeHeight = _paintGrid.length;

    if (_frames.isNotEmpty) {
      _currentFrame = (_currentFrame + 1) % _frames.length;
      newGrid = _frames[_currentFrame];
    }

    var canvas = List.generate(badgeHeight, (i) => List.generate(badgeWidth, (j) => false));

    _currentAnimation.processAnimation(badgeHeight, badgeWidth, _animationIndex, newGrid, canvas);

    for (var effect in _currentEffect) {
      effect?.processEffect(_animationIndex, canvas, badgeHeight, badgeWidth);
    }

    _paintGrid = canvas;
    if (!_isDisposed) notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    _currentEffect.clear();
    _frames.clear();
    _paintGrid.clear();
    _newGrid.clear();
    super.dispose();
    logger.d("AnimationBadgeProvider disposed");
  }

  Future<void> handleAnimationTransfer({
    required BadgeMessageProvider badgeData,
    required InlineImageProvider inlineImageProvider,
    required SpeedDialProvider speedDialProvider,
    required bool flash,
    required bool marquee,
    required bool invert,
    required int badgeHeight,
    required int badgeWidth,
  }) async {
    if (_isDisposed) return;

    final int aniIndex = getAnimationIndex() ?? 0;
    final int selectedSpeed = speedDialProvider.getOuterValue();

    if (aniIndex == 9) {
      await transferPacmanAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 10) {
      await transferChevronAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 11) {
      await transferDiamondAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 12) {
      await transferBrokenHeartsAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 13) {
      await transferCupidAnimation(badgeData, selectedSpeed);
      setAnimationMode(CupidAnimation());
      _animationIndex = 0;
      if (_timer == null || !_timer!.isActive) startTimer();
    } else if (aniIndex == 14) {
      await transferFeetAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 15) {
      await transferFishAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 16) {
      await transferDiagonalAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 17) {
      await transferEmergencyAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 18) {
      await transferBeatingHeartsAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 19) {
      await transferFireworksAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 20) {
      await transferEqualizerAnimation(badgeData, selectedSpeed);
    } else if (aniIndex == 21) {
      await transferCycleAnimation(badgeData, selectedSpeed);
    } else {
      await badgeData.checkAndTransfer(
        inlineImageProvider.getController().text,
        flash,
        marquee,
        invert,
        selectedSpeed,
        modeValueMap[aniIndex],
        null,
        false,
        badgeHeight,
        badgeWidth,
      );
    }
  }
}
