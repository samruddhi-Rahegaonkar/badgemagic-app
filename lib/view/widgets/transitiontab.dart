import 'package:badgemagic/view/widgets/animation_container.dart';
import 'package:flutter/material.dart';

import 'package:badgemagic/bademagic_module/models/screen_size.dart';

// Transition tab to show special animations
class TransitionTab extends StatefulWidget {
  final ScreenSize selectedSize;

  const TransitionTab({super.key, required this.selectedSize});

  @override
  State<TransitionTab> createState() => _TransitionTabState();
}

class _TransitionTabState extends State<TransitionTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                AniContainer(
                  animation: null,
                  icon: Icons.sports_esports, // Pacman icon
                  animationName: 'Pacman',
                  index: 9,
                  screenSize: widget.selectedSize,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.chevron_left, // Chevron icon
                  animationName: 'Chevron',
                  index: 10,
                  screenSize: widget.selectedSize,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.diamond, // Diamond icon
                  animationName: 'Diamond',
                  index: 11,
                  screenSize: widget.selectedSize,
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
                  icon: Icons.heart_broken, // Broken Hearts icon
                  animationName: 'Broken Hearts',
                  index: 12,
                  screenSize: widget.selectedSize,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.favorite_border, // Cupid icon
                  animationName: 'Cupid',
                  index: 13,
                  screenSize: widget.selectedSize,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.directions_walk, // Feet animation icon
                  animationName: 'Feet',
                  index: 14,
                  screenSize: widget.selectedSize,
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
                  icon: Icons.set_meal, // Fish icon
                  animationName: 'Fish Kiss',
                  index: 15,
                  screenSize: widget.selectedSize,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.change_history, // V shape icon
                  animationName: 'Diagonal',
                  index: 16,
                  screenSize: widget.selectedSize,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.warning, // Emergency/alert icon
                  animationName: 'Emergency',
                  index: 17,
                  screenSize: widget.selectedSize,
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
                  icon: Icons.favorite, // Heart icon
                  animationName: 'Beating Hearts',
                  index: 18,
                  screenSize: widget.selectedSize,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.celebration, // Fireworks icon
                  animationName: 'Fireworks',
                  index: 19,
                  screenSize: widget.selectedSize,
                ),
                AniContainer(
                  animationName: 'Equalizer',
                  index: 20, // This MUST match the index in your animationMap
                  icon: Icons.equalizer,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
