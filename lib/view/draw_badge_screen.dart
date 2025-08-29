import 'package:badgemagic/bademagic_module/models/screen_size.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/virtualbadge/view/draw_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DrawBadge extends StatefulWidget {
  final String? filename;
  final bool? isSavedCard;
  final bool? isSavedClipart;
  final List<List<int>>? badgeGrid;
  final ScreenSize selectedSize;

  const DrawBadge({
    super.key,
    this.filename,
    this.isSavedCard = false,
    this.isSavedClipart = false,
    this.badgeGrid,
    required this.selectedSize,
  });

  @override
  State<DrawBadge> createState() => _DrawBadgeState();
}

class _DrawBadgeState extends State<DrawBadge> {
  late DrawBadgeProvider drawToggle;
  bool _showShapeOptions = false;

  @override
  void initState() {
    super.initState();
    drawToggle = DrawBadgeProvider();
    drawToggle.initGridWithSize(widget.selectedSize);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLandscapeOrientation();
    });
  }

  @override
  void dispose() {
    _resetPortraitOrientation();
    super.dispose();
  }

  Future<void> _resetPortraitOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (e) {
      logger.e('Error setting portrait orientation', error: e);
    }
  }

  Future<void> _setLandscapeOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    } catch (e) {
      logger.e('Error setting landscape orientation', error: e);
    }
  }

  Future<void> _saveImage() async {
    try {
      List<List<int>> badgeGrid = drawToggle
          .getDrawViewGrid()
          .map((e) => e.map((e) => e ? 1 : 0).toList())
          .toList();
      List<String> hexString =
          Converters.convertBitmapToLEDHex(badgeGrid, false);

      if (widget.isSavedCard == true) {
        await FileHelper().updateBadgeText(
          widget.filename ?? '',
          hexString,
        );
      } else if (widget.isSavedClipart == true) {
        await FileHelper().updateClipart(
          widget.filename ?? '',
          badgeGrid,
        );
      } else {
        await FileHelper().saveImage(drawToggle.getDrawViewGrid());
      }

      await FileHelper().generateClipartCache();
      ToastUtils().showToast("Clipart Saved Successfully");
    } catch (e) {
      logger.e('Error saving image', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) {
          await _resetPortraitOrientation();
        }
      },
      child: CommonScaffold(
        index: 1,
        title: 'BadgeMagic',
        body: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          key: const Key(drawBadgeScreen),
          child: Align(
            alignment: Alignment.center,
            child: LayoutBuilder(
              builder: (context, constraints) => Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.94,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge preview
                    BMBadge(
                      providerInit: (provider) => drawToggle = provider,
                      badgeGrid: widget.badgeGrid
                          ?.map((e) => e.map((e) => e == 1).toList())
                          .toList(),
                      selectedSize: widget.selectedSize,
                    ),

                    const SizedBox(height: 12),

                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCompactButton(true, Icons.edit, 'Draw'),
                        const SizedBox(width: 8),
                        _buildCompactButton(false, Icons.delete, 'Erase'),
                        const SizedBox(width: 8),
                        _buildResetButton(),
                        const SizedBox(width: 8),
                        _buildSaveButton(),
                        const SizedBox(width: 8),
                        _buildShapesToggleButton(),
                      ],
                    ),

                    // Shape options
                    if (_showShapeOptions)
                      Container(
                        height: 60,
                        margin: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildCompactShapeCard(
                                DrawShape.freehand, Icons.gesture, 'Free'),
                            const SizedBox(width: 6),
                            _buildCompactShapeCard(
                                DrawShape.square, Icons.crop_square, 'Square'),
                            const SizedBox(width: 6),
                            _buildCompactShapeCard(DrawShape.rectangle,
                                Icons.rectangle_outlined, 'Rect'),
                            const SizedBox(width: 6),
                            _buildCompactShapeCard(DrawShape.circle,
                                Icons.circle_outlined, 'Circle'),
                            const SizedBox(width: 6),
                            _buildCompactShapeCard(DrawShape.triangle,
                                Icons.change_history, 'Triangle'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactButton(bool isDraw, IconData icon, String label) {
    final isSelected = drawToggle.isDrawing == isDraw;

    return TextButton(
      onPressed: () {
        setState(() {
          drawToggle.toggleIsDrawing(isDraw);
        });
      },
      child: Column(
        children: [
          Icon(icon, color: isSelected ? colorPrimary : Colors.black, size: 20),
          Text(label,
              style: TextStyle(
                  color: isSelected ? colorPrimary : Colors.black,
                  fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          drawToggle.resetDrawViewGrid();
        });
      },
      child: const Column(
        children: [
          Icon(Icons.refresh, color: Colors.black, size: 20),
          Text('Reset', style: TextStyle(color: Colors.black, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return TextButton(
      onPressed: () async {
        await _saveImage();
        Future.delayed(const Duration(milliseconds: 800), () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        });
      },
      child: const Column(
        children: [
          Icon(Icons.save, color: Colors.black, size: 20),
          Text('Save', style: TextStyle(color: Colors.black, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildShapesToggleButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _showShapeOptions = !_showShapeOptions;
          if (!_showShapeOptions) {
            drawToggle.setShape(DrawShape.freehand);
          }
        });
      },
      child: Column(
        children: [
          Icon(Icons.category,
              color: _showShapeOptions ? colorPrimary : Colors.black, size: 20),
          Text('Shapes',
              style: TextStyle(
                  color: _showShapeOptions ? colorPrimary : Colors.black,
                  fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildCompactShapeCard(DrawShape shape, IconData icon, String label) {
    final isSelected = drawToggle.selectedShape == shape;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          drawToggle.setShape(shape);
        });
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : Colors.black,
        backgroundColor: isSelected ? colorPrimary : Colors.white,
        elevation: isSelected ? 2 : 1,
        side:
            BorderSide(color: isSelected ? colorPrimary : Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        minimumSize: const Size(55, 40),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18),
          Text(label,
              style: const TextStyle(fontSize: 9),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
