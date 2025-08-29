import 'package:flutter/material.dart';
import 'package:badgemagic/bademagic_module/models/screen_size.dart';
import 'package:badgemagic/badge_animation/ani_left.dart';
import 'package:badgemagic/badge_animation/animation_abstract.dart';

enum DrawShape { freehand, square, rectangle, circle, triangle }

class DrawBadgeProvider extends ChangeNotifier {
  List<List<bool>> _drawViewGrid = [];
  List<List<bool>> _previewGrid = [];
  ScreenSize _currentSize = supportedScreenSizes.first;
  bool isDrawing = true;
  DrawShape _selectedShape = DrawShape.freehand;
  BadgeAnimation currentAnimation = LeftAnimation();
  int get rows => _drawViewGrid.length;
  int get cols => _drawViewGrid.isNotEmpty ? _drawViewGrid[0].length : 0;

  DrawShape get selectedShape => _selectedShape;
  ScreenSize getCurrentSize() => _currentSize;
  bool getIsDrawing() => isDrawing;

  List<List<bool>> getDrawViewGrid() {
    return List.generate(
      rows,
      (i) => List.generate(cols, (j) {
        return _drawViewGrid[i][j] || _previewGrid[i][j];
      }),
    );
  }

  void toggleIsDrawing(bool drawing) {
    isDrawing = drawing;
    notifyListeners();
  }

  void setShape(DrawShape shape) {
    _selectedShape = shape;
    notifyListeners();
  }

  void initGridWithSize(ScreenSize size) {
    _currentSize = size;
    _drawViewGrid = List.generate(
      size.height,
      (_) => List.generate(size.width, (_) => false),
    );
    _previewGrid = List.generate(
      size.height,
      (_) => List.generate(size.width, (_) => false),
    );
    notifyListeners();
  }

  void resetDrawViewGrid() {
    _drawViewGrid =
        List.generate(rows, (_) => List.generate(cols, (_) => false));
    notifyListeners();
  }

  void clearPreviewGrid() {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        _previewGrid[i][j] = false;
      }
    }
  }

  void commitGridUpdate() {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (_previewGrid[i][j]) {
          _drawViewGrid[i][j] = true;
        }
      }
    }
    clearPreviewGrid();
    notifyListeners();
  }

  void setCell(int row, int col, bool value, {bool preview = false}) {
    if (row >= 0 && row < rows && col >= 0 && col < cols) {
      if (preview) {
        _previewGrid[row][col] = value;
      } else {
        _drawViewGrid[row][col] = value;
      }
      notifyListeners();
    }
  }

  void setDrawViewGrid(int row, int col) {
    if (row >= 0 && row < rows && col >= 0 && col < cols) {
      _drawViewGrid[row][col] = isDrawing;
      notifyListeners();
    }
  }

  void updateDrawViewGrid(List<List<bool>> badgeData) {
    final r = _drawViewGrid.length;
    final c = _drawViewGrid.isNotEmpty ? _drawViewGrid[0].length : 0;

    for (int i = 0; i < r; i++) {
      for (int j = 0; j < c; j++) {
        _drawViewGrid[i][j] = false;
      }
    }

    for (int i = 0; i < r && i < badgeData.length; i++) {
      for (int j = 0; j < c && j < badgeData[i].length; j++) {
        _drawViewGrid[i][j] = badgeData[i][j];
      }
    }

    notifyListeners();
  }

  GridPosition getGridPosition(Offset position, double cellSize) {
    final row = (position.dy / cellSize).floor();
    final col = (position.dx / cellSize).floor();
    return GridPosition(row, col);
  }
}

class GridPosition {
  final int row;
  final int col;
  GridPosition(this.row, this.col);
}
