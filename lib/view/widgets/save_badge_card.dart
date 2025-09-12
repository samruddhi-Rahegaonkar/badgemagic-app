import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/badge_slot_provider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/view/draw_badge_screen.dart';
import 'package:badgemagic/view/widgets/badge_delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class SaveBadgeCard extends StatelessWidget {
  final MapEntry<String, Map<String, dynamic>> badgeData;
  final Future<void> Function(MapEntry<String, Map<String, dynamic>>)
      refreshBadgesCallback;
  final FileHelper file = FileHelper();
  final Converters converters = Converters();
  final ToastUtils toastUtils = ToastUtils();
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  SaveBadgeCard({
    super.key,
    required this.badgeData,
    required this.refreshBadgesCallback,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    BadgeMessageProvider badge = BadgeMessageProvider();
    return Container(
      width: 370.w,
      padding: EdgeInsets.all(6.dg),
      margin: EdgeInsets.all(10.dg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.dg),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Text(
                    badgeData.key.substring(0, badgeData.key.length - 5),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              Consumer<SavedBadgeProvider>(
                builder: (context, provider, widget) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ▶️ Play animation
                    IconButton(
                      icon: Image.asset(
                        "assets/icons/t_play.png",
                        height: 20,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        provider.savedBadgeAnimation(
                          badgeData.value,
                          Provider.of<AnimationBadgeProvider>(context,
                              listen: false),
                        );
                      },
                    ),
                    // ✏️ Edit badge
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black),
                      onPressed: () {
                        List<List<int>> data = hexStringToBool(
                          file.jsonToData(badgeData.value).messages[0].text.join(),
                        ).map((e) => e.map((e) => e ? 1 : 0).toList()).toList();

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DrawBadge(
                              filename: badgeData.key,
                              isSavedCard: true,
                              badgeGrid: data,
                            ),
                          ),
                        );
                      },
                    ),
                    // 🔄 Transfer to badge
                    IconButton(
                      icon: Image.asset(
                        "assets/icons/t_updown.png",
                        height: 24.h,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        badge.checkAndTransfer(
                          null,
                          null,
                          null,
                          null,
                          null,
                          null,
                          badgeData.value,
                          true,
                          context,
                        );
                      },
                    ),
                    // 📤 Share badge
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.black),
                      onPressed: () {
                        file.shareBadgeData(badgeData.key);
                      },
                    ),
                    // 🗑️ Delete badge
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.black),
                      onPressed: () async {
                        final confirm = await _showDeleteDialog(context);
                        if (confirm == true) {
                          file.deleteFile(badgeData.key);
                          toastUtils.showToast("Badge Deleted Successfully");
                          await refreshBadgesCallback(badgeData);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Row(
                children: [
                  Visibility(
                    visible: file.jsonToData(badgeData.value).messages[0].flash,
                    child: _chipIcon("assets/icons/flash.png"),
                  ),
                  SizedBox(width: 8.w),
                  Visibility(
                    visible: file.jsonToData(badgeData.value).messages[0].marquee,
                    child: _chipIcon("assets/icons/square.png"),
                  ),
                  SizedBox(width: 8.w),
                  Visibility(
                    visible: badgeData.value['messages'][0]['invert'] ?? false,
                    child: _chipIcon("assets/icons/t_invert.png"),
                  ),
                ],
              ),
              SizedBox(width: 8.w),
              _chipWithText(
                icon: "assets/icons/t_double.png",
                text: Speed.getIntValue(
                  file.jsonToData(badgeData.value).messages[0].speed,
                ).toString(),
              ),
              SizedBox(width: 8.w),
              _chipWithText(
                text: file
                    .jsonToData(badgeData.value)
                    .messages[0]
                    .mode
                    .toString()
                    .split('.')
                    .last
                    .toUpperCase(),
              ),
              const Spacer(),
              Consumer<BadgeSlotProvider>(
                builder: (context, selectionProvider, _) {
                  final isSelected = selectionProvider.isSelected(badgeData.key);
                  return Switch(
                    value: isSelected,
                    onChanged: (selectionProvider.canSelectMore || isSelected)
                        ? (value) => selectionProvider.toggleSelection(badgeData.key)
                        : null,
                    activeThumbColor: colorPrimary,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipIcon(String asset) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: colorPrimary,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Image.asset(asset, color: Colors.white, height: 14.h),
    );
  }

  Widget _chipWithText({String? icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: colorPrimary,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Image.asset(icon, color: Colors.white, height: 14.h),
            const SizedBox(width: 4),
          ],
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => DeleteBadgeDialog(),
    );
  }
}
