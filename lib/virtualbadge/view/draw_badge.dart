import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:badgemagic/virtualbadge/view/badge_paint.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BMBadge extends StatefulWidget {
  final void Function(DrawBadgeProvider provider)? providerInit;
  final List<List<bool>>? badgeGrid;
  const BMBadge({super.key, this.providerInit, this.badgeGrid});

  @override
  State<BMBadge> createState() => _BMBadgeState();
}

class _BMBadgeState extends State<BMBadge> {
  static const int rows = 11;
  static const int cols = 44;

  final drawProvider = DrawBadgeProvider();
  Offset? dragStart;
  int shapeSize = 1;

  @override
  void initState() {
    super.initState();
    if (widget.providerInit != null) {
      widget.providerInit!(drawProvider);
    }
    if (widget.badgeGrid != null) {
      drawProvider.updateDrawViewGrid(widget.badgeGrid!);
    }
  }

  double get _cellSize => MediaQuery.of(context).size.width / cols;

  Offset _getLocalPosition(Offset globalPosition) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    return renderBox.globalToLocal(globalPosition);
  }

  void _handlePanStart(DragStartDetails details) {
    dragStart = _getLocalPosition(details.globalPosition);
    shapeSize = 1;
  }

  void _handlePanEnd(DragEndDetails details) {
    dragStart = null;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final localPosition = _getLocalPosition(details.globalPosition);

    final currentCol =
        (localPosition.dx / _cellSize).floor().clamp(0, cols - 1);
    final currentRow =
        (localPosition.dy / _cellSize).floor().clamp(0, rows - 1);
    final shape = drawProvider.selectedShape;

    if (shape == DrawShape.freehand) {
      if (dragStart == null) {
        dragStart = localPosition;
        return;
      }

      final previousCol =
          (dragStart!.dx / _cellSize).floor().clamp(0, cols - 1);
      final previousRow =
          (dragStart!.dy / _cellSize).floor().clamp(0, rows - 1);

      _drawLine(previousRow, previousCol, currentRow, currentCol);
      dragStart = localPosition;
      return;
    }

    // For shape drawing
    if (dragStart != null) {
      final startCol = (dragStart!.dx / _cellSize).floor().clamp(0, cols - 1);
      final startRow = (dragStart!.dy / _cellSize).floor().clamp(0, rows - 1);

      shapeSize =
          ((currentRow - startRow).abs() + (currentCol - startCol).abs()) ~/ 2;

      // Draw without clearing previous shapes
      switch (shape) {
        case DrawShape.square:
          _drawSquare(
              startRow, startCol, shapeSize, drawProvider.getIsDrawing());
          break;
        case DrawShape.rectangle:
          _drawRectangle(startRow, startCol, shapeSize, (shapeSize / 2).round(),
              drawProvider.getIsDrawing());
          break;
        case DrawShape.circle:
          _drawCircle(
              startRow, startCol, shapeSize, drawProvider.getIsDrawing());
          break;
        case DrawShape.triangle:
          _drawTriangle(
              startRow, startCol, shapeSize, drawProvider.getIsDrawing());
          break;
        default:
          break;
      }
    }

    setState(() {});
  }

  void _drawLine(int r1, int c1, int r2, int c2) {
    drawProvider.getIsDrawing();

    int dx = (c2 - c1).abs();
    int dy = (r2 - r1).abs();
    int sx = c1 < c2 ? 1 : -1;
    int sy = r1 < r2 ? 1 : -1;
    int err = dx - dy;

    int x = c1;
    int y = r1;

    while (true) {
      drawProvider.setDrawViewGrid(y, x);
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

  void _drawSquare(int row, int col, int radius, bool state) {
    for (int i = -radius; i <= radius; i++) {
      for (int j = -radius; j <= radius; j++) {
        _safeSet(row + i, col + j, state);
      }
    }
  }

  void _drawRectangle(
      int row, int col, int halfWidth, int halfHeight, bool state) {
    for (int i = -halfHeight; i <= halfHeight; i++) {
      for (int j = -halfWidth; j <= halfWidth; j++) {
        _safeSet(row + i, col + j, state);
      }
    }
  }

  void _drawCircle(int row, int col, int radius, bool state) {
    for (int i = -radius; i <= radius; i++) {
      for (int j = -radius; j <= radius; j++) {
        if ((i * i + j * j) <= radius * radius) {
          _safeSet(row + i, col + j, state);
        }
      }
    }
  }

  void _drawTriangle(int row, int col, int height, bool state) {
    for (int i = 0; i <= height; i++) {
      for (int j = -i; j <= i; j++) {
        _safeSet(row + i, col + j, state);
      }
    }
  }

  void _safeSet(int row, int col, bool value) {
    if (row >= 0 && row < rows && col >= 0 && col < cols) {
      drawProvider.getDrawViewGrid()[row][col] = value;
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    Size size = Size(width, width / 3.2);

    return ChangeNotifierProvider.value(
      value: drawProvider,
      child: GestureDetector(
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: AspectRatio(
          aspectRatio: 3.2,
          child: Consumer<DrawBadgeProvider>(
            builder: (context, value, child) => CustomPaint(
              painter: BadgePaint(grid: value.getDrawViewGrid()),
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}

// class AnimationBadgeROW extends LeafRenderObjectWidget {
//   final DrawBadgeProvider provider;

//   const AnimationBadgeROW({super.key, required this.provider});

//   @override
//   RenderObject createRenderObject(BuildContext context) {
//     final renderObject = BadgeRenderObject(provider: provider);
//     provider.addListener(renderObject.onProviderUpdate);
//     return renderObject;
//   }

//   @override
//   void updateRenderObject(
//       BuildContext context, covariant BadgeRenderObject renderObject) {
//     renderObject.provider = provider;
//   }
// }

// class BadgeRenderObject extends RenderBox with RenderObjectWithChildMixin {
//   DrawBadgeProvider provider;

//   BadgeRenderObject({required this.provider});

//   @override
//   void performLayout() {
//     var width = constraints.maxWidth;
//     var height = constraints.maxHeight;

//     // Maintain aspect ratio but ensure it fits within the available height
//     var desiredHeight = width / 3.2;
//     if (desiredHeight > height) {
//       desiredHeight = height;
//     }

//     size = constraints.constrain(Size(width, desiredHeight));
//   }

//   @override
//   void paint(PaintingContext context, Offset offset) {
//     final Canvas canvas = context.canvas;
//     BadgePaint(grid: provider.getDrawViewGrid()).paint(canvas, size);
//   }

//   @override
//   bool get alwaysNeedsCompositing => true;

//   void onProviderUpdate() {
//     markNeedsPaint();
//   }

//   @override
//   bool hitTest(BoxHitTestResult result, {required Offset position}) {
//     if (size.contains(position)) {
//       result.add(BoxHitTestEntry(this, position));
//       return true;
//     }
//     return false;
//   }
// }
