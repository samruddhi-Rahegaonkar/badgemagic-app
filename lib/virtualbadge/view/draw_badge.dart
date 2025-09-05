// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:badgemagic/bademagic_module/models/screen_size.dart';
import 'package:badgemagic/bademagic_module/utils/badge_utils.dart';
import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:badgemagic/virtualbadge/view/badge_paint.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BMBadge extends StatefulWidget {
  final void Function(DrawBadgeProvider provider)? providerInit;
  final List<List<bool>>? badgeGrid;
  final ScreenSize selectedSize;

  const BMBadge({
    super.key,
    this.providerInit,
    this.badgeGrid,
    required this.selectedSize,
  });

  @override
  State<BMBadge> createState() => _BMBadgeState();
}

class _BMBadgeState extends State<BMBadge> {
  BadgeUtils badgeUtils = BadgeUtils();
  late DrawBadgeProvider drawProvider;
  Offset? dragStart;

  @override
  void initState() {
    super.initState();
    drawProvider = DrawBadgeProvider();
    drawProvider.initGridWithSize(widget.selectedSize);

    if (widget.providerInit != null) {
      widget.providerInit!(drawProvider);
    }
    if (widget.badgeGrid != null) {
      drawProvider.updateDrawViewGrid(widget.badgeGrid!);
    }
  }

  @override
  void didUpdateWidget(covariant BMBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSize != oldWidget.selectedSize) {
      drawProvider.initGridWithSize(widget.selectedSize);
    }
  }

  Offset _getLocalPosition(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox;
    return renderBox.globalToLocal(globalPosition);
  }

  void _handlePanStart(DragStartDetails details) {
    dragStart = _getLocalPosition(details.globalPosition);
    drawProvider.pushToUndoStack(); // Save state for undo
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    final rows = widget.selectedSize.height;
    final cols = widget.selectedSize.width;

    // Background offsets + badge scaling
    final badgeOffsetBackground =
        badgeUtils.getBadgeOffsetBackground(renderBox.size);
    final offsetHeightBadgeBackground = badgeOffsetBackground.key;
    final offsetWidthBadgeBackground = badgeOffsetBackground.value;

    final badgeSize = badgeUtils.getBadgeSize(offsetHeightBadgeBackground,
        offsetWidthBadgeBackground, renderBox.size);
    final badgeHeight = badgeSize.key;
    final badgeWidth = badgeSize.value;

    final cellSize = badgeWidth / cols;

    final cellStartCoordinate = badgeUtils.getCellStartCoordinate(
        offsetWidthBadgeBackground,
        offsetHeightBadgeBackground,
        badgeWidth,
        badgeHeight);
    final cellStartX = cellStartCoordinate.key;
    final cellStartY = cellStartCoordinate.value;

    final cellEndX = cellStartX + (cellSize * cols);
    final cellEndY = cellStartY + ((cellSize * 0.93) * rows);

    if (localPosition.dx >= cellStartX &&
        localPosition.dy >= cellStartY &&
        localPosition.dx < cellEndX &&
        localPosition.dy < cellEndY * 1.1) {
      final shape = drawProvider.selectedShape;

      final start = drawProvider.getGridPosition(dragStart!, cellSize);
      final end = drawProvider.getGridPosition(localPosition, cellSize);

      drawProvider.clearPreviewGrid();

      switch (shape) {
        case DrawShape.freehand:
          _drawLine(start.row, start.col, end.row, end.col, preview: false);
          dragStart = localPosition;
          drawProvider.commitGridUpdate();
          break;
        case DrawShape.square:
          final size =
              ((end.row - start.row).abs() + (end.col - start.col).abs()) ~/ 2;
          _drawSquare(start.row, start.col, size, preview: true);
          break;
        case DrawShape.rectangle:
          final w = (end.col - start.col).abs() ~/ 2;
          final h = (end.row - start.row).abs() ~/ 2;
          _drawRectangle(start.row, start.col, h, w, preview: true);
          break;
        case DrawShape.circle:
          final radius =
              ((end.row - start.row).abs() + (end.col - start.col).abs()) ~/ 2;
          _drawCircle(start.row, start.col, radius, preview: true);
          break;
        case DrawShape.triangle:
          final height = (end.row - start.row).abs();
          _drawTriangle(start.col, start.col, height, preview: true);
          break;
      }

      // ignore: invalid_use_of_protected_member
      drawProvider.notifyListeners();
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (drawProvider.selectedShape != DrawShape.freehand) {
      drawProvider.commitGridUpdate();
    }
    dragStart = null;
  }

  void _drawLine(int r1, int c1, int r2, int c2, {bool preview = false}) {
    int dx = (c2 - c1).abs(), dy = (r2 - r1).abs();
    int sx = c1 < c2 ? 1 : -1;
    int sy = r1 < r2 ? 1 : -1;
    int err = dx - dy, x = c1, y = r1;

    while (true) {
      drawProvider.setCell(y, x, drawProvider.getIsDrawing(), preview: preview);
      if (x == c2 && y == r2) break;
      int e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x += sx;
      }
      if (e2 < dx) {
        err += dx;
        y += sy;
      }
    }
  }

  void _drawSquare(int row, int col, int radius, {bool preview = false}) {
    for (int i = -radius; i <= radius; i++) {
      for (int j = -radius; j <= radius; j++) {
        drawProvider.setCell(row + i, col + j, drawProvider.getIsDrawing(),
            preview: preview);
      }
    }
  }

  void _drawRectangle(int row, int col, int h, int w, {bool preview = false}) {
    for (int i = -h; i <= h; i++) {
      for (int j = -w; j <= w; j++) {
        drawProvider.setCell(row + i, col + j, drawProvider.getIsDrawing(),
            preview: preview);
      }
    }
  }

  void _drawCircle(int row, int col, int radius, {bool preview = false}) {
    for (int i = -radius; i <= radius; i++) {
      for (int j = -radius; j <= radius; j++) {
        if ((i * i + j * j) <= radius * radius) {
          drawProvider.setCell(row + i, col + j, drawProvider.getIsDrawing(),
              preview: preview);
        }
      }
    }
  }

  void _drawTriangle(int row, int col, int height, {bool preview = false}) {
    for (int i = 0; i <= height; i++) {
      for (int j = -i; j <= i; j++) {
        drawProvider.setCell(row + i, col + j, drawProvider.getIsDrawing(),
            preview: preview);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final aspectRatio = widget.selectedSize.width / widget.selectedSize.height;
    final width = MediaQuery.of(context).size.width;
    final size = Size(width, width / aspectRatio);

    return ChangeNotifierProvider.value(
      value: drawProvider,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Consumer<DrawBadgeProvider>(
            builder: (_, value, __) => CustomPaint(
              painter: BadgePaint(grid: value.getDrawViewGrid()),
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}
