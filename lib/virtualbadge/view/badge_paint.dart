import 'dart:math' as math;
import 'package:badgemagic/bademagic_module/utils/badge_utils.dart';
import 'package:flutter/material.dart';

class BadgePaint extends CustomPainter {
  BadgeUtils badgeUtils = BadgeUtils();
  final List<List<bool>> grid;

  // Cell horizontal spacing factor to prevent crowding (1.0 = no spacing)
  static const double cellHorizontalSpacingFactor = 0.93;

  BadgePaint({required this.grid});

  @override
  void paint(Canvas canvas, Size size) {
    if (grid.isEmpty || grid[0].isEmpty) return;

    // Get padding offsets
    final badgeOffsetBackground = badgeUtils.getBadgeOffsetBackground(size);
    final offsetHeightBadgeBackground = badgeOffsetBackground.key;
    final offsetWidthBadgeBackground = badgeOffsetBackground.value;

    // Calculate badge dimensions
    final badgeSize = badgeUtils.getBadgeSize(
      offsetHeightBadgeBackground,
      offsetWidthBadgeBackground,
      size,
    );
    final badgeHeight = badgeSize.key;
    final badgeWidth = badgeSize.value;

    // Draw badge background
    final Paint rectPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black
      ..strokeWidth = 2.0;

    final RRect gridRect = RRect.fromLTRBR(
      offsetWidthBadgeBackground,
      offsetHeightBadgeBackground,
      offsetWidthBadgeBackground + badgeWidth,
      offsetHeightBadgeBackground + badgeHeight,
      const Radius.circular(10.0),
    );

    canvas.drawRRect(gridRect, rectPaint);

    final int cols = grid[0].length;
    final int rows = grid.length;

    // Adjust cell size to fit grid inside badge area
    final double cellWidth = badgeWidth / (cols * cellHorizontalSpacingFactor);
    final double cellHeight = badgeHeight / rows;
    final double cellSize = math.min(cellWidth, cellHeight);

    // Compute cell grid start coordinates
    final cellStartCoordinate = badgeUtils.getCellStartCoordinate(
      offsetWidthBadgeBackground,
      offsetHeightBadgeBackground,
      badgeWidth,
      badgeHeight,
    );
    final cellStartX = cellStartCoordinate.key;
    final cellStartY = cellStartCoordinate.value;

    // Draw pixel grid
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final double cellStartRow = cellStartY + row * cellSize;
        final double cellStartCol =
            cellStartX + col * (cellSize * cellHorizontalSpacingFactor);

        final Paint paint = Paint()
          ..color = grid[row][col] ? Colors.red : Colors.grey.shade900
          ..style = PaintingStyle.fill;

        final Rect cellRect = Rect.fromLTWH(
          cellStartCol,
          cellStartRow,
          cellSize * 0.5, // Width may be adjusted separately if needed
          cellSize,
        );

        // Rotate cell by 45 degrees to give LED pixel look
        canvas.save();
        canvas.translate(
          cellRect.left + (cellRect.width / 2),
          cellRect.top + (cellRect.height / 2),
        );
        canvas.rotate(math.pi / 4);
        canvas.translate(
          -(cellRect.left + (cellRect.width / 2)),
          -(cellRect.top + (cellRect.height / 2)),
        );

        canvas.drawRect(cellRect, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! BadgePaint) return true;
    return oldDelegate.grid != grid;
  }
}
