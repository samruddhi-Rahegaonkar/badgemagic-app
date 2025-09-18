import 'package:badgemagic/services/localization_service.dart';
import 'package:badgemagic/view/widgets/animation_container.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/bademagic_module/models/screen_size.dart';

class TransitionTab extends StatefulWidget {
  final ScreenSize selectedSize;

  const TransitionTab({super.key, required this.selectedSize});

  @override
  State<TransitionTab> createState() => _TransitionTabState();
}

class _TransitionTabState extends State<TransitionTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    final horizontalPadding = 8.0;

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 6.0,
      radius: const Radius.circular(6),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          children: [
            _buildTileRow([
              AniContainer(
                animation: null,
                icon: Icons.sports_esports,
                animationName: l10n.animationPacman,
                index: 9,
                screenSize: widget.selectedSize,
              ),
              AniContainer(
                animation: null,
                icon: Icons.chevron_left,
                animationName: l10n.animationChevron,
                index: 10,
                screenSize: widget.selectedSize,
              ),
              AniContainer(
                animation: null,
                icon: Icons.diamond,
                animationName: l10n.animationDiamond,
                index: 11,
                screenSize: widget.selectedSize,
              ),
            ]),
            _buildTileRow([
              AniContainer(
                animation: null,
                icon: Icons.heart_broken,
                animationName: l10n.animationBrokenHearts,
                index: 12,
                screenSize: widget.selectedSize,
              ),
              AniContainer(
                animation: null,
                icon: Icons.favorite_border,
                animationName: l10n.animationCupid,
                index: 13,
                screenSize: widget.selectedSize,
              ),
              AniContainer(
                animation: null,
                icon: Icons.directions_walk,
                animationName: l10n.animationFeet,
                index: 14,
                screenSize: widget.selectedSize,
              ),
            ]),
            _buildTileRow([
              AniContainer(
                animation: null,
                icon: Icons.set_meal,
                animationName: l10n.animationFishKiss,
                index: 15,
                screenSize: widget.selectedSize,
              ),
              AniContainer(
                animation: null,
                icon: Icons.change_history,
                animationName: l10n.animationDiagonal,
                index: 16,
                screenSize: widget.selectedSize,
              ),
              AniContainer(
                animation: null,
                icon: Icons.warning,
                animationName: l10n.animationEmergency,
                index: 17,
                screenSize: widget.selectedSize,
              ),
            ]),
            _buildTileRow([
              AniContainer(
                animation: null,
                icon: Icons.favorite,
                animationName: l10n.animationBeatingHearts,
                index: 18,
                screenSize: widget.selectedSize,
              ),
              AniContainer(
                animation: null,
                icon: Icons.celebration,
                animationName: l10n.animationFireworks,
                index: 19,
                screenSize: widget.selectedSize,
              ),
              AniContainer(
                animation: null,
                icon: Icons.equalizer,
                animationName: l10n.animationEqualizer,
                index: 20,
                screenSize: widget.selectedSize,
              ),
            ]),
            _buildTileRow([
              AniContainer(
                animation: null,
                icon: Icons.directions_bike,
                animationName: l10n.animationCycle,
                index: 21,
                screenSize: widget.selectedSize,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTileRow(List<AniContainer> tiles) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: tiles.length == 1
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceEvenly,
        children: tiles.map((tile) {
          return tiles.length == 1
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: tile,
                )
              : Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: tile,
                  ),
                );
        }).toList(),
      ),
    );
  }
}
