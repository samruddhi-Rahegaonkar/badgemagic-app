import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:badgemagic/bademagic_module/models/screen_size.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:get_it/get_it.dart';

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
  late TextEditingController badgeNameController;

  @override
  void initState() {
    super.initState();
    selectedSize = widget.selectedSize;
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    badgeNameController = TextEditingController(
      text: '${l10n.badge} ${DateTime.now()}',
    );
    // Select all text on open
    badgeNameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: badgeNameController.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    final savedBadgeProvider = SavedBadgeProvider();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Container(
        height: 300.h,
        width: 300.w,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.saveBadge,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.h),
            Text(
              l10n.badgeName,
              style: const TextStyle(
                  fontWeight: FontWeight.w400, color: Colors.red),
            ),
            TextField(
              controller: badgeNameController,
              autofocus: true,
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              l10n.selectScreenSize,
              style: const TextStyle(
                  fontWeight: FontWeight.w400, color: Colors.red),
            ),
            DropdownButton<ScreenSize>(
              value: selectedSize,
              isExpanded: true,
              items: supportedScreenSizes.map((size) {
                return DropdownMenuItem<ScreenSize>(
                  value: size,
                  child: Text(size.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedSize = value);
                }
              },
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel,
                      style: const TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () async {
                    final trimmedName = badgeNameController.text.trim();
                    if (trimmedName.isEmpty) {
                      ToastUtils().showToast(l10n.enterValidBadgeName);
                      return;
                    }

                    final dir = await getApplicationDocumentsDirectory();
                    final filePath = '${dir.path}/$trimmedName.json';
                    final file = File(filePath);

                    // Case-insensitive check
                    final files = dir.listSync();
                    String? ciMatch;
                    for (var f in files) {
                      if (f is File) {
                        final name = f.path.split(Platform.pathSeparator).last;
                        if (name.toLowerCase().endsWith('.json')) {
                          final base =
                              name.substring(0, name.length - 5).trim();
                          if (base.toLowerCase() == trimmedName.toLowerCase()) {
                            ciMatch = name;
                            break;
                          }
                        }
                      }
                    }

                    final exists = await file.exists();

                    if (exists || ciMatch != null) {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(exists
                              ? l10n.badgeNameExists
                              : l10n.similarBadgeExists),
                          content: Text(exists
                              ? l10n.badgeExistsMessage
                              : l10n.similarBadgeExistsMessage(
                                  ciMatch!.substring(0, ciMatch.length - 5))),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, 'rename'),
                                child: Text(l10n.cancel)),
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, 'update'),
                                child: Text(l10n.overwrite)),
                          ],
                        ),
                      );
                      if (result == 'rename') {
                        ToastUtils().showToast(l10n.pleaseEnterNewBadgeName);
                        return;
                      } else if (result == 'update') {
                        if (ciMatch != null) {
                          final existingFile = File('${dir.path}/$ciMatch');
                          await existingFile.writeAsString('');
                        }
                      } else {
                        return;
                      }
                    }

                    // Save badge
                    savedBadgeProvider.saveBadgeData(
                      trimmedName,
                      widget.textController.text,
                      widget.animationProvider.isEffectActive(FlashEffect()),
                      widget.animationProvider.isEffectActive(MarqueeEffect()),
                      widget.isInverse,
                      widget.speed.getOuterValue(),
                      widget.animationProvider.getAnimationIndex() ?? 1,
                      selectedSize.height,
                      selectedSize.width,
                    );
                    ToastUtils().showToast(
                      exists || ciMatch != null
                          ? l10n.badgeUpdatedSuccessfully
                          : l10n.badgeSavedSuccessfully,
                    );
                    Navigator.of(context).pop();
                  },
                  child:
                      Text('Save', style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
