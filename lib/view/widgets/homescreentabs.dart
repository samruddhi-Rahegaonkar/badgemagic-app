import 'package:badgemagic/constants.dart';
import 'package:badgemagic/view/widgets/animation_container.dart';
import 'package:badgemagic/view/widgets/effects_container.dart';
import 'package:flutter/material.dart';

//effects tab to show effects that the user can select
import 'package:badgemagic/bademagic_module/models/screen_size.dart';

class EffectTab extends StatefulWidget {
  final ScreenSize selectedSize;

  const EffectTab({super.key, required this.selectedSize});

  @override
  State<EffectTab> createState() => _EffectsTabState();
}

class _EffectsTabState extends State<EffectTab> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EffectContainer(
          effect: effInvert,
          effectName: 'Invert',
          index: 0,
          selectedSize: widget.selectedSize,
        ),
        EffectContainer(
          effect: effFlash,
          effectName: 'Effect',
          index: 1,
          selectedSize: widget.selectedSize,
        ),
        EffectContainer(
          effect: effMarque,
          effectName: 'Marquee',
          index: 2,
          selectedSize: widget.selectedSize,
        ),
      ],
    );
  }
}

//Animation tab to show animation choices for the user
class AnimationTab extends StatefulWidget {
  const AnimationTab({
    super.key,
  });

  @override
  State<AnimationTab> createState() => _AnimationTabState();
}

class _AnimationTabState extends State<AnimationTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            AniContainer(
              animation: aniLeft,
              animationName: 'Left',
              index: 0,
            ),
            AniContainer(
              animation: aniRight,
              animationName: 'Right',
              index: 1,
            ),
            AniContainer(
              animation: aniUp,
              animationName: 'Up',
              index: 2,
            ),
          ],
        ),
        Row(
          children: [
            AniContainer(
              animation: aniDown,
              animationName: 'Down',
              index: 3,
            ),
            AniContainer(
              animation: aniFixed,
              animationName: 'Fixed',
              index: 4,
            ),
            AniContainer(
              animation: aniFixed,
              animationName: 'Snowflake',
              index: 5,
            ),
          ],
        ),
        Row(
          children: [
            AniContainer(
              animation: aniPicture,
              animationName: 'Picture',
              index: 6,
            ),
            AniContainer(
              animation: animation,
              animationName: 'Animation',
              index: 7,
            ),
            AniContainer(
              animation: aniLaser,
              animationName: 'Laser',
              index: 8,
            ),
          ],
        ),
      ],
    );
  }
}
