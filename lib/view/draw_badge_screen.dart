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
  late DrawBadgeProvider drawToggle;
  bool _orientationSet = false;

  @override
  void initState() {
    super.initState();
    drawToggle = DrawBadgeProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLandscapeOrientation();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_orientationSet) {
      _orientationSet = true;
    }
  }

  @override
  void dispose() {
    try {
      _resetPortraitOrientation();
    } catch (e) {
      debugPrint('Error resetting orientation: $e');
    }
    super.dispose();
  }

  void _resetPortraitOrientation() {
    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (e) {
      debugPrint('Error setting portrait orientation: $e');
    }
  }

  void _setLandscapeOrientation() {
    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (e) {
      debugPrint('Error setting landscape orientation: $e');
    }
  }

  Future<void> _saveImage() async {
    try {
      FileHelper fileHelper = FileHelper();
      List<List<int>> badgeGrid = drawToggle
          .getDrawViewGrid()
          .map((e) => e.map((e) => e ? 1 : 0).toList())
          .toList();

      if (widget.isSavedCard == true) {
        await fileHelper.updateBadgeText(
          widget.filename ?? '',
          Converters.convertBitmapToLEDHex(badgeGrid, false),
        );
      } else if (widget.isSavedClipart == true) {
        await fileHelper.updateClipart(widget.filename ?? '', badgeGrid);
      } else {
        await fileHelper.saveImage(drawToggle.getDrawViewGrid());
      }

      await fileHelper.generateClipartCache();
      ToastUtils().showToast("Clipart Saved Successfully");
    } catch (e) {
      debugPrint('Error saving image: $e');
      ToastUtils().showToast("Failed to save clipart: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _resetPortraitOrientation();
        return true;
      },
      child: CommonScaffold(
        index: 1,
        title: 'BadgeMagic',
        body: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) => Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.94,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          width: 100,
                        ),
                        BMBadge(
                          providerInit: (provider) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                drawToggle = provider;
                              });
                            });
                          },
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
                          onPressed: _saveImage,
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
            ),
          ),
        ),
      ),
    );
  }
}

