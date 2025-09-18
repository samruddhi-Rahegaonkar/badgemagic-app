import 'package:badgemagic/constants.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/view/widgets/animation_container.dart';
import 'package:badgemagic/view/widgets/effects_container.dart';
import 'package:flutter/material.dart';
import 'package:badgemagic/bademagic_module/models/screen_size.dart';

class EffectTab extends StatefulWidget {
  final ScreenSize selectedSize;

  const EffectTab({super.key, required this.selectedSize});

  @override
  State<EffectTab> createState() => _EffectsTabState();
}

class _EffectsTabState extends State<EffectTab> {
  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EffectContainer(
          effect: effInvert,
          effectName: l10n.invertEffect,
          index: 0,
          selectedSize: widget.selectedSize,
        ),
        EffectContainer(
          effect: effFlash,
          effectName: l10n.flashEffect,
          index: 1,
          selectedSize: widget.selectedSize,
        ),
        EffectContainer(
          effect: effMarque,
          effectName: l10n.marqueeEffect,
          index: 2,
          selectedSize: widget.selectedSize,
        ),
      ],
    );
  }
}

class AnimationTab extends StatefulWidget {
  final ScreenSize selectedSize;

  const AnimationTab({super.key, required this.selectedSize});

  @override
  State<AnimationTab> createState() => _AnimationTabState();
}

class _AnimationTabState extends State<AnimationTab> {
  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return SingleChildScrollView(
      child: Column(
        children: [
          // Original animations from issue1344
          Row(
            children: [
              AniContainer(
                animation: aniLeft,
                animationName: 'Left',
                index: 0,
                screenSize: widget.selectedSize,
              ),
              AniContainer(
                animation: aniRight,
                animationName: 'Right',
                index: 1,
                screenSize: widget.selectedSize,
              ),
              AniContainer(
                animation: aniUp,
                animationName: 'Up',
                index: 2,
                screenSize: widget.selectedSize,
              ),
            ],
          ),
          Row(
            children: [
              AniContainer(
                animation: aniDown,
                animationName: 'Down',
                index: 3,
                screenSize: widget.selectedSize,
              ),
              AniContainer(
                animation: aniFixed,
                animationName: 'Fixed',
                index: 4,
                screenSize: widget.selectedSize,
              ),
              AniContainer(
                animation: animation,
                animationName: 'Animation',
                index: 5,
                screenSize: widget.selectedSize,
              ),
            ],
          ),
          Row(
            children: [
              AniContainer(
                animation: aniSnowflake,
                animationName: 'Snowflake',
                index: 6,
                screenSize: widget.selectedSize,
              ),
              AniContainer(
                animation: aniPicture,
                animationName: 'Picture',
                index: 7,
                screenSize: widget.selectedSize,
              ),
              AniContainer(
                animation: aniLaser,
                animationName: 'Laser',
                index: 8,
                screenSize: widget.selectedSize,
              ),
            ],
          ),

          // Additional animations from development
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                AniContainer(
                  animation: null,
                  icon: Icons.sports_esports,
                  animationName: l10n.pacman,
                  index: 9,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.chevron_left,
                  animationName: l10n.chevron,
                  index: 10,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.diamond,
                  animationName: l10n.diamond,
                  index: 11,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                AniContainer(
                  animation: null,
                  icon: Icons.heart_broken,
                  animationName: l10n.brokenHearts,
                  index: 12,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.favorite_border,
                  animationName: l10n.cupid,
                  index: 13,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.directions_walk,
                  animationName: l10n.feet,
                  index: 14,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                AniContainer(
                  animation: null,
                  icon: Icons.set_meal,
                  animationName: l10n.fishKiss,
                  index: 15,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.change_history,
                  animationName: l10n.diagonal,
                  index: 16,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.warning,
                  animationName: l10n.emergency,
                  index: 17,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                AniContainer(
                  animation: null,
                  icon: Icons.favorite,
                  animationName: l10n.beatingHearts,
                  index: 18,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.celebration,
                  animationName: l10n.fireworks,
                  index: 19,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.equalizer,
                  animationName: l10n.equalizer,
                  index: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
