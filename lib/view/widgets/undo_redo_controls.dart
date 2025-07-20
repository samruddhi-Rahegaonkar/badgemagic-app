import 'package:flutter/material.dart';
import 'package:badgemagic/providers/draw_badge_provider.dart';

class UndoRedoControls extends StatelessWidget {
  final DrawBadgeProvider drawProvider;

  const UndoRedoControls({super.key, required this.drawProvider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Undo',
          onPressed: drawProvider.canUndo
              ? () {
                  drawProvider.undo();
                }
              : null,
          icon: const Icon(Icons.undo),
        ),
        IconButton(
          tooltip: 'Redo',
          onPressed: drawProvider.canRedo
              ? () {
                  drawProvider.redo();
                }
              : null,
          icon: const Icon(Icons.redo),
        ),
      ],
    );
  }
}
