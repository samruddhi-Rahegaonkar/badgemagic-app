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
            return SingleChildScrollView(
              key: const Key(drawBadgeScreen),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        const SizedBox(width: 100),
                        BMBadge(
                          providerInit: (provider) => drawToggle = provider,
                          badgeGrid: widget.badgeGrid
                              ?.map((e) => e.map((e) => e == 1).toList())
                              .toList(),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              drawToggle.toggleIsDrawing(true);
                            });
                          },
                          child: Column(
                            children: [
                              Icon(
                                Icons.edit,
                                color: drawToggle.getIsDrawing()
                                    ? colorPrimary
                                    : Colors.black,
                              ),
                              Text(
                                'Draw',
                                style: TextStyle(
                                  color: drawToggle.isDrawing
                                      ? colorPrimary
                                      : Colors.black,
                                ),
                              )
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              drawToggle.toggleIsDrawing(false);
                            });
                          },
                          child: Column(
                            children: [
                              Icon(
                                Icons.delete,
                                color: drawToggle.isDrawing
                                    ? Colors.black
                                    : colorPrimary,
                              ),
                              Text(
                                'Erase',
                                style: TextStyle(
                                  color: drawToggle.isDrawing
                                      ? Colors.black
                                      : colorPrimary,
                                ),
                              )
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              drawToggle.resetDrawViewGrid();
                            });
                          },
                          child: const Column(
                            children: [
                              Icon(
                                Icons.refresh,
                                color: Colors.black,
                              ),
                              Text(
                                'Reset',
                                style: TextStyle(color: Colors.black),
                              )
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            List<List<int>> badgeGrid = drawToggle
                                .getDrawViewGrid()
                                .map((e) => e.map((e) => e ? 1 : 0).toList())
                                .toList();
                            List<String> hexString =
                                Converters.convertBitmapToLEDHex(
                                    badgeGrid, false);

                            if (widget.isSavedCard!) {
                              fileHelper.updateBadgeText(
                                  widget.filename!, hexString);
                            } else if (widget.isSavedClipart!) {
                              fileHelper.updateClipart(
                                  widget.filename!, badgeGrid);
                            } else {
                              fileHelper
                                  .saveImage(drawToggle.getDrawViewGrid());
                            }

                            fileHelper.generateClipartCache();

                            // Show toast first
                            ToastUtils()
                                .showToast("Clipart Saved Successfully");

                            // Delay redirection slightly to ensure toast is visible
                            Future.delayed(const Duration(milliseconds: 800),
                                () {
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            });
                          },
                          child: const Column(
                            children: [
                              Icon(
                                Icons.save,
                                color: Colors.black,
                              ),
                              Text('Save',
                                  style: TextStyle(color: Colors.black))
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawEraseButton(bool isDraw, IconData icon, String label) {
    final isSelected = drawToggle.isDrawing == isDraw;

    return TextButton(
      onPressed: () {
        setState(() {
          drawToggle.toggleIsDrawing(isDraw);
        });
      },
      child: Column(
        children: [
          Icon(icon, color: isSelected ? colorPrimary : Colors.black),
          Text(label,
              style:
                  TextStyle(color: isSelected ? colorPrimary : Colors.black)),
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
          Icon(Icons.refresh, color: Colors.black),
          Text('Reset', style: TextStyle(color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildSaveButton(FileHelper fileHelper) {
    return TextButton(
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
      child: const Column(
        children: [
          Icon(Icons.save, color: Colors.black),
          Text('Save', style: TextStyle(color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildShapeCard(
      BuildContext context, DrawShape shape, IconData icon, String label) {
    final isSelected = drawToggle.selectedShape == shape;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            drawToggle.setShape(shape);
          });
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: isSelected ? Colors.white : Colors.black,
          backgroundColor: isSelected ? colorPrimary : Colors.white,
          elevation: isSelected ? 4 : 1,
          side: BorderSide(
              color: isSelected ? colorPrimary : Colors.grey.shade300),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
