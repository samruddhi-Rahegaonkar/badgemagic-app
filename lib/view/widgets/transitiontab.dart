import 'package:badgemagic/view/widgets/animation_container.dart';
import 'package:flutter/material.dart';

// Transition tab to show special animations
class TransitionTab extends StatefulWidget {
  const TransitionTab({super.key});

  @override
  State<TransitionTab> createState() => _TransitionTabState();
}

class _TransitionTabState extends State<TransitionTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              AniContainer(
                animation: null,
                icon: Icons.sports_esports, // Pacman icon
                animationName: 'Pacman',
                index: 9,
              ),
              AniContainer(
                animation: null,
                icon: Icons.chevron_left, // Chevron icon
                animationName: 'Chevron',
                index: 10,
              ),
              AniContainer(
                animation: null,
                icon: Icons.diamond, // Diamond icon
                animationName: 'Diamond',
                index: 11,
              ),
            ],
          ),
          Row(
            children: [
              AniContainer(
                animation: null,
                icon: Icons.heart_broken, // Broken Hearts icon
                animationName: 'Broken Hearts',
                index: 12,
              ),
              AniContainer(
                animation: null,
                icon: Icons.favorite_border, // Cupid icon
                animationName: 'Cupid',
                index: 13,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
