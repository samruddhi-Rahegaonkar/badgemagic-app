import 'package:flutter/material.dart';
import 'package:badgemagic/bademagic_module/models/screen_size.dart';
import 'package:badgemagic/badge_animation/ani_left.dart';
import 'package:badgemagic/badge_animation/animation_abstract.dart';

enum DrawShape { freehand, square, rectangle, circle, triangle }

class DrawBadgeProvider extends ChangeNotifier {
  List<List<bool>> _drawViewGrid = [];
  List<List<bool>> _previewGrid = [];
  final List<List<List<bool>>> _undoStack = [];
  final List<List<List<bool>>> _redoStack = [];

  ScreenSize _currentSize = supportedScreenSizes.first;
  bool isDrawing = true;
  DrawShape _selectedShape = DrawShape.freehand;
  BadgeAnimation currentAnimation = LeftAnimation();

  int get rows => _drawViewGrid.length;
  int get cols => _drawViewGrid.isNotEmpty ? _drawViewGrid[0].length : 0;

  // ========== GETTERS ==========
  List<List<bool>> getDrawViewGrid() {
    // Merge preview + permanent grid
    return List.generate(
      rows,
      (i) => List.generate(
        cols,
        (j) => _drawViewGrid[i][j] || _previewGrid[i][j],
      ),
    );
  }

  DrawShape get selectedShape => _selectedShape;
  ScreenSize getCurrentSize() => _currentSize;
  bool getIsDrawing() => isDrawing;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // ========== STATE SETTERS ==========
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
        size.height, (_) => List.generate(size.width, (_) => false));
    _previewGrid = List.generate(
        size.height, (_) => List.generate(size.width, (_) => false));
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

  void resetDrawViewGrid() {
    _pushToUndoStack();
    _drawViewGrid =
        List.generate(rows, (_) => List.generate(cols, (_) => false));
    notifyListeners();
  }

  void updateDrawViewGrid(List<List<bool>> badgeData) {
    _pushToUndoStack();
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        _drawViewGrid[i][j] = (i < badgeData.length && j < badgeData[i].length)
            ? badgeData[i][j]
            : false;
      }
    }
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
    _pushToUndoStack();
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

  GridPosition getGridPosition(Offset position, double cellSize) {
    final row = (position.dy / cellSize).floor();
    final col = (position.dx / cellSize).floor();
    return GridPosition(row, col);
  }

  // ========== UNDO / REDO ==========
  void _pushToUndoStack() {
    _undoStack.add(_copyGrid(_drawViewGrid));
    _redoStack.clear(); // Invalidate redo stack on new action
  }

  void pushToUndoStack() {
    _pushToUndoStack(); // Existing private method
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_copyGrid(_drawViewGrid));
      _drawViewGrid = _undoStack.removeLast();
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_copyGrid(_drawViewGrid));
      _drawViewGrid = _redoStack.removeLast();
      notifyListeners();
    }
  }

  List<List<bool>> _copyGrid(List<List<bool>> grid) {
    return grid.map((row) => List<bool>.from(row)).toList();
  }
}

class GridPosition {
  final int row;
  final int col;
  GridPosition(this.row, this.col);
}
