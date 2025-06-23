import 'package:badgemagic/bademagic_module/models/screen_size.dart';
import 'package:badgemagic/view/widgets/save_badge_card.dart';
import 'package:flutter/material.dart';

class BadgeListView extends StatelessWidget {
  final Future<List<MapEntry<String, Map<String, dynamic>>>> futureBadges;
  final bool isTransferEnabled;
  final Future<void> Function(MapEntry<String, Map<String, dynamic>>)
      refreshBadgesCallback; // Add callback for refreshing badges
  final ScreenSize selectedSize;

  const BadgeListView(
      {super.key,
      required this.isTransferEnabled,
      required this.futureBadges,
      required this.refreshBadgesCallback,
      required this.selectedSize // Require the callback
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MapEntry<String, Map<String, dynamic>>>>(
      future: futureBadges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          List<MapEntry<String, Map<String, dynamic>>> savedBadges =
              snapshot.data!;
          return Padding(
            padding: EdgeInsets.only(bottom: isTransferEnabled ? 75.0 : 0),
            child: ListView.builder(
              itemCount: savedBadges.length,
              itemBuilder: (context, index) {
                return SaveBadgeCard(
                  badgeData: savedBadges[index],
                  refreshBadgesCallback: refreshBadgesCallback,
                  selectedSize: selectedSize, // Pass callback to card
                );
              },
            ),
          );
        }
      },
    );
  }
}
