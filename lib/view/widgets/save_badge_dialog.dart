import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:badgemagic/bademagic_module/models/screen_size.dart';

class SaveBadgeDialog extends StatefulWidget {
  final SpeedDialProvider speed;
  final bool isInverse;
  final AnimationBadgeProvider animationProvider;
  final TextEditingController textController;
  final ScreenSize selectedSize;

  const SaveBadgeDialog({
    super.key,
    required this.textController,
    required this.isInverse,
    required this.animationProvider,
    required this.speed,
    required this.selectedSize,
  });

  @override
  State<SaveBadgeDialog> createState() => _SaveBadgeDialogState();
}

class _SaveBadgeDialogState extends State<SaveBadgeDialog> {
  late ScreenSize selectedSize;
  TextEditingController badgeNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedSize = widget.selectedSize;
    badgeNameController.text = DateTime.now().toString();
  }

  @override
  Widget build(BuildContext context) {
    SavedBadgeProvider savedBadgeProvider = SavedBadgeProvider();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Container(
        height: 250.h,
        width: 300.w,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Save Badge',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              'File Name',
              style: TextStyle(fontWeight: FontWeight.w400, color: Colors.red),
            ),
            TextField(
              controller: badgeNameController,
              autofocus: true,
            ),
            const SizedBox(height: 10),
            const Text(
              'Select Screen Size',
              style: TextStyle(fontWeight: FontWeight.w400, color: Colors.red),
            ),
            DropdownButton<ScreenSize>(
              value: selectedSize,
              hint: const Text("Choose size"),
              isExpanded: true,
              items: supportedScreenSizes.map((size) {
                return DropdownMenuItem<ScreenSize>(
                  value: size,
                  child: Text(size.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedSize = value;
                  });
                }
              },
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child:
                      const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () async {
                          final trimmedBadgeName =
                              badgeNameController.text.trim();
                          if (trimmedBadgeName.isEmpty) {
                            ToastUtils()
                                .showToast("Please enter a valid badge name.");
                            return;
                          }

                          final directory =
                              await getApplicationDocumentsDirectory();
                          final filePath =
                              '${directory.path}/$trimmedBadgeName.json';
                          final file = File(filePath);

                          // Check for any file(s) with the same name (case-insensitive)
                          final files = directory.listSync();
                          List<String> caseInsensitiveMatches = [];
                          for (var f in files) {
                            if (f is File) {
                              final filename =
                                  f.path.split(Platform.pathSeparator).last;
                              if (filename.toLowerCase().endsWith('.json')) {
                                final baseName = filename
                                    .substring(0, filename.length - 5)
                                    .trim();
                                if (baseName.toLowerCase() ==
                                    trimmedBadgeName.toLowerCase()) {
                                  caseInsensitiveMatches.add(filename);
                                }
                              }
                            }
                          }
                          String? caseInsensitiveMatch =
                              caseInsensitiveMatches.isNotEmpty
                                  ? caseInsensitiveMatches.first
                                  : null;

                          // Check for exact (case-sensitive) match
                          bool caseSensitiveExists = await file.exists();

                          if (caseSensitiveExists) {
                            // Exact same file exists
                            final result = await showDialog<String>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Badge name exists'),
                                content: const Text(
                                    'A badge with this name already exists. What would you like to do?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, 'rename'),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, 'update'),
                                    child: const Text('Overwrite'),
                                  ),
                                ],
                              ),
                            );
                            if (result == 'rename') {
                              ToastUtils()
                                  .showToast('Please enter a new badge name.');
                              return;
                            } else if (result == 'update') {
                              // Overwrite existing badge
                              savedBadgeProvider.saveBadgeData(
                                  badgeNameController.text,
                                  widget.textController.text,
                                  widget.animationProvider
                                      .isEffectActive(FlashEffect()),
                                  widget.animationProvider
                                      .isEffectActive(MarqueeEffect()),
                                  widget.isInverse,
                                  widget.speed.getOuterValue(),
                                  widget.animationProvider
                                          .getAnimationIndex() ??
                                      1,
                                  selectedSize.height,
                                  selectedSize.width);
                              ToastUtils()
                                  .showToast('Badge updated successfully.');
                              Navigator.of(context).pop();
                              return;
                            } else {
                              return;
                            }
                          } else if (caseInsensitiveMatch != null) {
                            // Case-insensitive match exists but not exact match
                            final result = await showDialog<String>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Similar badge name exists'),
                                content: Text(
                                    "A badge with a similar name already exists: '${caseInsensitiveMatch.substring(0, caseInsensitiveMatch.length - 5)}'. What would you like to do?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, 'rename'),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, 'update'),
                                    child: const Text('Overwrite'),
                                  ),
                                ],
                              ),
                            );
                            if (result == 'rename') {
                              ToastUtils()
                                  .showToast('Please enter a new badge name.');
                              return;
                            } else if (result == 'update') {
                              final existingFilePath =
                                  '${directory.path}/$caseInsensitiveMatch';
                              final existingFile = File(existingFilePath);
                              await existingFile.writeAsString('');
                              savedBadgeProvider.saveBadgeData(
                                  caseInsensitiveMatch.substring(
                                      0, caseInsensitiveMatch.length - 5),
                                  widget.textController.text,
                                  widget.animationProvider
                                      .isEffectActive(FlashEffect()),
                                  widget.animationProvider
                                      .isEffectActive(MarqueeEffect()),
                                  widget.isInverse,
                                  widget.speed.getOuterValue(),
                                  widget.animationProvider
                                          .getAnimationIndex() ??
                                      1,
                                  selectedSize.height,
                                  selectedSize.width);
                              ToastUtils()
                                  .showToast('Badge updated successfully.');
                              Navigator.of(context).pop();
                              return;
                            } else {
                              return;
                            }
                          } else {
                            // File does not exist, save as new
                            savedBadgeProvider.saveBadgeData(
                                badgeNameController.text,
                                widget.textController.text,
                                widget.animationProvider
                                    .isEffectActive(FlashEffect()),
                                widget.animationProvider
                                    .isEffectActive(MarqueeEffect()),
                                widget.isInverse,
                                widget.speed.getOuterValue(),
                                widget.animationProvider.getAnimationIndex() ??
                                    1,
                                selectedSize.height,
                                selectedSize.width);
                            ToastUtils().showToast('Badge saved successfully.');
                            Navigator.of(context).pop();
                          }
                        },
                  child:
                      const Text('Save', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
