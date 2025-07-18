import 'package:badgemagic/badge_animation/ani_left.dart';
import 'package:badgemagic/badge_animation/animation_abstract.dart';
import 'package:flutter/material.dart';

// Optional: shape enum, doesn't affect freehand
enum DrawShape { freehand, square, rectangle, circle, triangle }

class DrawBadgeProvider extends ChangeNotifier {
  // 11x44 LED grid, default all false (off)
  List<List<bool>> _drawViewGrid =
      List.generate(11, (i) => List.generate(44, (j) => false));

  // Drawing mode (true = draw, false = erase)
  bool isDrawing = true;

  // Currently selected shape
  DrawShape _selectedShape = DrawShape.freehand;

  // Animation used in badge (not part of drawing)
  BadgeAnimation currentAnimation = LeftAnimation();

  // Return the current grid
  List<List<bool>> getDrawViewGrid() => _drawViewGrid;

  // Return current drawing mode
  bool getIsDrawing() => isDrawing;

  // Return selected shape
  DrawShape get selectedShape => _selectedShape;

  // Toggle between drawing and erasing
  void toggleIsDrawing(bool drawing) {
    isDrawing = drawing;
    notifyListeners();
  }

  // Set selected shape
  void setShape(DrawShape shape) {
    _selectedShape = shape;
    notifyListeners();
  }

  // Set a single LED (used by gesture drawing)
  void setDrawViewGrid(int row, int col) {
    // Only allow grid update for freehand drawing
    if (_selectedShape == DrawShape.freehand) {
      if (row >= 0 &&
          row < _drawViewGrid.length &&
          col >= 0 &&
          col < _drawViewGrid[0].length) {
        _drawViewGrid[row][col] = isDrawing;
        notifyListeners();
      }
    }
  }

  // Reset the grid to all OFF
  void resetDrawViewGrid() {
    _drawViewGrid = List.generate(11, (i) => List.generate(44, (j) => false));
    notifyListeners();
  }

  // Load a grid into the draw view
  void updateDrawViewGrid(List<List<bool>> badgeData) {
    for (int i = 0; i < _drawViewGrid.length; i++) {
      for (int j = 0; j < _drawViewGrid[0].length; j++) {
        if (j < badgeData[0].length) {
          _drawViewGrid[i][j] = badgeData[i][j];
        } else {
          _drawViewGrid[i][j] = false;
        }
      }
    }
    notifyListeners();
  }
}
