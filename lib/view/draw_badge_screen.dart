import 'package:badgemagic/bademagic_module/models/screen_size.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:get_it/get_it.dart';
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
  final FileHelper fileHelper = FileHelper();
  final l10n = GetIt.instance.get<LocalizationService>().l10n;

  @override
  void initState() {
    super.initState();
    drawToggle = DrawBadgeProvider();
    drawToggle.initGridWithSize(widget.selectedSize);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _setLandscapeOrientation());
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
          .map((row) => row.map((cell) => cell ? 1 : 0).toList())
          .toList();
      List<String> hexString =
          Converters.convertBitmapToLEDHex(badgeGrid, false);

      if (widget.isSavedCard!) {
        await fileHelper.updateBadgeText(widget.filename!, hexString);
      } else if (widget.isSavedClipart!) {
        await fileHelper.updateClipart(widget.filename!, badgeGrid);
      } else {
        await fileHelper.saveImage(drawToggle.getDrawViewGrid());
      }

      await fileHelper.generateClipartCache();
      ToastUtils().showToast(l10n.clipartSavedSuccessfully);
    } catch (e) {
      logger.e('Error saving image', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _resetPortraitOrientation();
        return true;
      },
      child: CommonScaffold(
        index: 1,
        title: l10n.appTitle,
        body: LayoutBuilder(
          builder: (context, constraints) => Column(
            key: const Key(drawBadgeScreen),
            children: [
              const SizedBox(height: 8),

              // Badge Preview
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: BMBadge(
                    providerInit: (provider) => drawToggle = provider,
                    badgeGrid: widget.badgeGrid
                        ?.map((row) => row.map((e) => e == 1).toList())
                        .toList(),
                    selectedSize: widget.selectedSize,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Control Buttons
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                            child: _buildCompactButton(
                                true, Icons.edit, l10n.draw)),
                        const SizedBox(width: 2),
                        Flexible(
                            child: _buildCompactButton(
                                false, Icons.delete, l10n.erase)),
                        const SizedBox(width: 2),
                        Flexible(child: _buildResetButton()),
                        const SizedBox(width: 2),
                        Flexible(child: _buildSaveButton()),
                        const SizedBox(width: 2),
                        Flexible(child: _buildShapesToggleButton()),
                        const SizedBox(width: 2),
                        Flexible(child: _buildUndoButton()),
                        const SizedBox(width: 2),
                        Flexible(child: _buildRedoButton()),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Shape Options
                    if (_showShapeOptions)
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildCompactShapeCard(
                                DrawShape.freehand, Icons.gesture, l10n.free),
                            const SizedBox(width: 2),
                            _buildCompactShapeCard(DrawShape.square,
                                Icons.crop_square, l10n.square),
                            const SizedBox(width: 2),
                            _buildCompactShapeCard(DrawShape.rectangle,
                                Icons.rectangle_outlined, l10n.rectangle),
                            const SizedBox(width: 2),
                            _buildCompactShapeCard(DrawShape.circle,
                                Icons.circle_outlined, l10n.circle),
                            const SizedBox(width: 2),
                            _buildCompactShapeCard(DrawShape.triangle,
                                Icons.change_history, l10n.triangle),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactButton(bool isDraw, IconData icon, String label) {
    final isSelected = drawToggle.isDrawing == isDraw;
    return TextButton(
      onPressed: () => setState(() => drawToggle.toggleIsDrawing(isDraw)),
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

  Widget _buildResetButton() => TextButton(
        onPressed: () => setState(() => drawToggle.resetDrawViewGrid()),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          minimumSize: const Size(60, 40),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh, color: Colors.black, size: 20),
            const SizedBox(height: 2),
            Text(l10n.reset,
                style: const TextStyle(color: Colors.black, fontSize: 10)),
          ],
        ),
      );

  Widget _buildSaveButton() => TextButton(
        onPressed: () async {
          await _saveImage();
          if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          minimumSize: const Size(60, 40),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.save, color: Colors.black, size: 20),
            const SizedBox(height: 2),
            Text(l10n.save,
                style: const TextStyle(color: Colors.black, fontSize: 10)),
          ],
        ),
      );

  Widget _buildShapesToggleButton() => TextButton(
        onPressed: () {
          setState(() {
            _showShapeOptions = !_showShapeOptions;
            if (!_showShapeOptions) drawToggle.setShape(DrawShape.freehand);
          });
        },
        child: Column(
          children: [
            Icon(Icons.category,
                color: _showShapeOptions ? colorPrimary : Colors.black,
                size: 20),
            const SizedBox(height: 2),
            Text('Shapes',
                style: TextStyle(
                    color: _showShapeOptions ? colorPrimary : Colors.black,
                    fontSize: 10)),
          ],
        ),
      );

  Widget _buildUndoButton() => AnimatedBuilder(
        animation: drawToggle,
        builder: (context, _) {
          final canUndo = drawToggle.canUndo;
          return TextButton(
            onPressed: canUndo ? drawToggle.undo : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.undo,
                    color: canUndo ? Colors.black : Colors.grey, size: 20),
                const SizedBox(height: 2),
                Text('Undo',
                    style: TextStyle(
                        color: canUndo ? Colors.black : Colors.grey,
                        fontSize: 10)),
              ],
            ),
          );
        },
      );

  Widget _buildRedoButton() => AnimatedBuilder(
        animation: drawToggle,
        builder: (context, _) {
          final canRedo = drawToggle.canRedo;
          return TextButton(
            onPressed: canRedo ? drawToggle.redo : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.redo,
                    color: canRedo ? Colors.black : Colors.grey, size: 20),
                const SizedBox(height: 2),
                Text('Redo',
                    style: TextStyle(
                        color: canRedo ? Colors.black : Colors.grey,
                        fontSize: 10)),
              ],
            ),
          );
        },
      );

  Widget _buildCompactShapeCard(DrawShape shape, IconData icon, String label) {
    final isSelected = drawToggle.selectedShape == shape;
    return ElevatedButton(
      onPressed: () => setState(() => drawToggle.setShape(shape)),
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
