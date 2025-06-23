import 'package:flutter/material.dart';
import 'package:badgemagic/bademagic_module/models/screen_size.dart';

class DrawBadgeProvider extends ChangeNotifier {
  List<List<bool>> _drawViewGrid = [];
  ScreenSize _currentSize = supportedScreenSizes.first;
  bool isDrawing = true;

  List<List<bool>> getDrawViewGrid() => _drawViewGrid;

  bool getIsDrawing() => isDrawing;

  void toggleIsDrawing(bool drawing) {
    isDrawing = drawing;
    notifyListeners();
  }

  ScreenSize getCurrentSize() => _currentSize;

  void setDrawViewGrid(int row, int col) {
    _drawViewGrid[row][col] = isDrawing;
    notifyListeners();
  }

  void initGridWithSize(ScreenSize size) {
    _currentSize = size;
    _drawViewGrid = List.generate(
      size.height,
      (_) => List.generate(size.width, (_) => false),
    );
    notifyListeners();
  }

  void updateDrawViewGrid(List<List<bool>> badgeData) {
    final rows = _drawViewGrid.length;
    final cols = _drawViewGrid.isNotEmpty ? _drawViewGrid[0].length : 0;

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        _drawViewGrid[i][j] = false;
      }
    }

    for (int i = 0; i < rows && i < badgeData.length; i++) {
      for (int j = 0; j < cols && j < badgeData[i].length; j++) {
        _drawViewGrid[i][j] = badgeData[i][j];
      }
    }

    notifyListeners();
  }

  void resetDrawViewGrid() {
    _drawViewGrid = List.generate(
      _currentSize.height,
      (_) => List.generate(_currentSize.width, (_) => false),
    );
    notifyListeners();
  }
}
