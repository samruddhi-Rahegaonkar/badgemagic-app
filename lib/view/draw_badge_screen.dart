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

  const DrawBadge({
    super.key,
    this.filename,
    this.isSavedCard = false,
    this.isSavedClipart = false,
    this.badgeGrid,
  });

  @override
  State<DrawBadge> createState() => _DrawBadgeState();
}

class _DrawBadgeState extends State<DrawBadge> {
  var drawToggle = DrawBadgeProvider();
  bool _showShapeOptions = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setLandscapeOrientation();
  }

  @override
  void dispose() {
    _resetPortraitOrientation();
    super.dispose();
  }

  void _resetPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    FileHelper fileHelper = FileHelper();

    return WillPopScope(
      onWillPop: () async {
        _resetPortraitOrientation();
        return true;
      },
      child: CommonScaffold(
        index: 1,
        title: 'BadgeMagic',
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              key: const Key(drawBadgeScreen),
              children: [
                const SizedBox(height: 8),

                // Badge takes most of the available space
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: BMBadge(
                      providerInit: (provider) => drawToggle = provider,
                      badgeGrid: widget.badgeGrid
                          ?.map((e) => e.map((e) => e == 1).toList())
                          .toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Control buttons - compact layout
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Main action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCompactButton(true, Icons.edit, 'Draw'),
                          _buildCompactButton(false, Icons.delete, 'Erase'),
                          _buildResetButton(),
                          _buildSaveButton(fileHelper),
                          _buildShapesToggleButton(),
                        ],
                      ),
                    ],
                  ),
                ),

                // Shape options - only show when toggled, fixed height
                if (_showShapeOptions)
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCompactShapeCard(
                            context, DrawShape.freehand, Icons.gesture, 'Free'),
                        _buildCompactShapeCard(context, DrawShape.square,
                            Icons.crop_square, 'Square'),
                        _buildCompactShapeCard(context, DrawShape.rectangle,
                            Icons.rectangle_outlined, 'Rect'),
                        _buildCompactShapeCard(context, DrawShape.circle,
                            Icons.circle_outlined, 'Circle'),
                        _buildCompactShapeCard(context, DrawShape.triangle,
                            Icons.change_history, 'Triangle'),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactButton(bool isDraw, IconData icon, String label) {
    final isSelected = drawToggle.isDrawing == isDraw;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: TextButton(
          onPressed: () {
            setState(() {
              drawToggle.toggleIsDrawing(isDraw);
            });
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: isSelected ? colorPrimary : Colors.black, size: 20),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      color: isSelected ? colorPrimary : Colors.black,
                      fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: TextButton(
          onPressed: () {
            setState(() {
              drawToggle.resetDrawViewGrid();
            });
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh, color: Colors.black, size: 20),
              SizedBox(height: 2),
              Text('Reset',
                  style: TextStyle(color: Colors.black, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(FileHelper fileHelper) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: TextButton(
          onPressed: () {
            List<List<int>> badgeGrid = drawToggle
                .getDrawViewGrid()
                .map((e) => e.map((e) => e ? 1 : 0).toList())
                .toList();
            List<String> hexString =
                Converters.convertBitmapToLEDHex(badgeGrid, false);

            if (widget.isSavedCard!) {
              fileHelper.updateBadgeText(widget.filename!, hexString);
            } else if (widget.isSavedClipart!) {
              fileHelper.updateClipart(widget.filename!, badgeGrid);
            } else {
              fileHelper.saveImage(drawToggle.getDrawViewGrid());
            }

            fileHelper.generateClipartCache();
            ToastUtils().showToast("Clipart Saved Successfully");

            Future.delayed(const Duration(milliseconds: 800), () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            });
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.save, color: Colors.black, size: 20),
              SizedBox(height: 2),
              Text('Save', style: TextStyle(color: Colors.black, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShapesToggleButton() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: TextButton(
          onPressed: () {
            setState(() {
              _showShapeOptions = !_showShapeOptions;

              // Reset to Freehand when hiding shape options
              if (!_showShapeOptions) {
                drawToggle.setShape(DrawShape.freehand);
              }
            });
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
        ),
      ),
    );
  }

  Widget _buildCompactShapeCard(
      BuildContext context, DrawShape shape, IconData icon, String label) {
    final isSelected = drawToggle.selectedShape == shape;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              drawToggle.setShape(shape);
            });
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: isSelected ? Colors.white : Colors.black,
            backgroundColor: isSelected ? colorPrimary : Colors.white,
            elevation: isSelected ? 2 : 1,
            side: BorderSide(
                color: isSelected ? colorPrimary : Colors.grey.shade300),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(fontSize: 9),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
