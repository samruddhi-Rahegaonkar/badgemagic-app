import 'package:badgemagic/bademagic_module/models/screen_size.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/badge_slot_provider..dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/view/homescreen.dart';
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
  final void Function(ScreenSize)? onPreviewSizeChanged;

  SaveBadgeCard({
    super.key,
    required this.badgeData,
    required this.refreshBadgesCallback,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
    this.onPreviewSizeChanged,
  });

  // Get the screen size from badge data, default to first supported size
  ScreenSize getBadgeScreenSize() {
    final data = badgeData.value;
    if (data.containsKey('height') && data.containsKey('width')) {
      final height = data['height'] as int?;
      final width = data['width'] as int?;
      if (height != null && width != null) {
        return supportedScreenSizes.firstWhere(
            (size) => size.height == height && size.width == width,
            orElse: () => supportedScreenSizes.first);
      }
    }
    return supportedScreenSizes.first;
  }

  // Helper methods to safely access badge data properties
  bool _safeGetFlashValue(Map<String, dynamic> data) {
    try {
      return file.jsonToData(data).messages[0].flash;
    } catch (e) {
      // If there's an error, default to false
      return false;
    }
  }

  bool _safeGetMarqueeValue(Map<String, dynamic> data) {
    try {
      return file.jsonToData(data).messages[0].marquee;
    } catch (e) {
      // If there's an error, default to false
      return false;
    }
  }

  bool _safeGetInvertValue(Map<String, dynamic> data) {
    try {
      if (data.containsKey('messages') &&
          data['messages'] is List &&
          data['messages'].isNotEmpty &&
          data['messages'][0] is Map<String, dynamic>) {
        return data['messages'][0]['invert'] ?? false;
      }
      return false;
    } catch (e) {
      // If there's an error, default to false
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    BadgeMessageProvider badge = BadgeMessageProvider();
    return GestureDetector(
        onLongPress: onLongPress,
        onTap: onTap,
        child: Container(
          width: 380.w,
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
            border:
                isSelected ? Border.all(color: colorPrimary, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Wrapping the text with Flexible to ensure it doesn't overflow.
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: 8
                              .w), // Adding some padding to separate text and buttons
                      child: Text(
                        badgeData.key.substring(0, badgeData.key.length - 5),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        softWrap: true,
                        overflow: TextOverflow
                            .ellipsis, // Use ellipsis to indicate overflowed text
                        maxLines: 1, // Limit to 1 line for a cleaner look
                      ),
                    ),
                  ),
                  Consumer<SavedBadgeProvider>(
                    builder: (context, provider, widget) => Row(
                      mainAxisSize: MainAxisSize.min, // Keep the row compact
                      children: [
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
                              getBadgeScreenSize().height,
                            );
                            onPreviewSizeChanged?.call(getBadgeScreenSize());
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.black,
                          ),
                          onPressed: () async {
                            hexStringToBool(
                                    file
                                        .jsonToData(badgeData.value)
                                        .messages[0]
                                        .text
                                        .join(),
                                    getBadgeScreenSize().height)
                                .map((e) => e.map((v) => v == 1).toList())
                                .toList();
                            final shouldEdit = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Edit Badge'),
                                content: const Text(
                                    'Do you want to edit this badge?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Yes'),
                                  ),
                                ],
                              ),
                            );
                            if (shouldEdit == true) {
                              // Extract the speed value from the saved badge
                              final speed = Speed.getIntValue(file
                                  .jsonToData(badgeData.value)
                                  .messages[0]
                                  .speed);
                              String badgeFilename = badgeData.key;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => HomeScreen(
                                    savedBadgeFilename: badgeFilename,
                                    initialSpeed: speed,
                                    // Pass the speed value
                                  ),
                                ),
                                (route) => false, // Remove all previous routes
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: Image.asset(
                            "assets/icons/t_updown.png",
                            height: 24.h,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            logger.d("BadgeData: ${badgeData.value}");
                            //We can Acrtually call a method to generate the data just by transffering the JSON data
                            //so we would not necessarily need the Providers.
                            badge.checkAndTransfer(
                                null,
                                null,
                                null,
                                null,
                                null,
                                null,
                                badgeData.value,
                                true,
                                getBadgeScreenSize().height,
                                getBadgeScreenSize().width);
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.share,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            file.shareBadgeData(badgeData.key);
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.black,
                          ),
                          onPressed: () async {
                            //add a dialog for confirmation before deleting
                            await _showDeleteDialog(context)
                                .then((value) async {
                              if (value == true) {
                                file.deleteFile(badgeData.key);
                                toastUtils
                                    .showToast("Badge Deleted Successfully");
                                await refreshBadgesCallback(badgeData);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              // Solution 1: Wrap the Row in a SingleChildScrollView for horizontal scrolling
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Visibility(
                            visible: _safeGetFlashValue(badgeData.value),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: colorPrimary,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    "assets/icons/flash.png",
                                    color: Colors.white,
                                    height: 14.h,
                                  )
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Visibility(
                            visible: _safeGetMarqueeValue(badgeData.value),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: colorPrimary,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    "assets/icons/square.png",
                                    color: Colors.white,
                                    height: 14.h,
                                  )
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Visibility(
                            visible: _safeGetInvertValue(badgeData.value),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: colorPrimary,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    "assets/icons/t_invert.png",
                                    color: Colors.white,
                                    height: 14.h,
                                  )
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: colorPrimary,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    "assets/icons/t_double.png",
                                    color: Colors.white,
                                    height: 14.h,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    Speed.getIntValue(file
                                            .jsonToData(badgeData.value)
                                            .messages[0]
                                            .speed)
                                        .toString(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: colorPrimary,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                file
                                    .jsonToData(badgeData.value)
                                    .messages[0]
                                    .mode
                                    .toString()
                                    .split('.')
                                    .last
                                    .toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: colorPrimary,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                getBadgeScreenSize().name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Consumer<BadgeSlotProvider>(
                    builder: (context, selectionProvider, _) {
                      final isSelected =
                          selectionProvider.isSelected(badgeData.key);
                      return Switch(
                        value: isSelected,
                        onChanged: (selectionProvider.canSelectMore ||
                                isSelected)
                            ? (value) {
                                // Check screen size compatibility
                                final provider =
                                    Provider.of<InlineImageProvider>(context,
                                        listen: false);
                                final selectedBadges =
                                    selectionProvider.selectedBadges;
                                if (selectedBadges.isNotEmpty && !isSelected) {
                                  // Check if any selected badge has different screen size
                                  bool hasMismatch = false;
                                  ScreenSize currentSize = getBadgeScreenSize();
                                  for (var key in selectedBadges) {
                                    final selectedBadgeData = provider
                                        .savedBadgeCache
                                        .firstWhere(
                                            (element) => element.key == key)
                                        .value;
                                    int? height = selectedBadgeData['height'];
                                    int? width = selectedBadgeData['width'];
                                    ScreenSize selectedSize;
                                    if (height != null && width != null) {
                                      selectedSize =
                                          supportedScreenSizes.firstWhere(
                                              (size) =>
                                                  size.height == height &&
                                                  size.width == width,
                                              orElse: () =>
                                                  supportedScreenSizes.first);
                                    } else {
                                      selectedSize = supportedScreenSizes.first;
                                    }
                                    if (selectedSize != currentSize) {
                                      hasMismatch = true;
                                      break;
                                    }
                                  }
                                  if (hasMismatch) {
                                    toastUtils.showToast(
                                        'Cannot select badges with different screen sizes.');
                                    return;
                                  }
                                }
                                selectionProvider
                                    .toggleSelection(badgeData.key);
                              }
                            : null,
                        activeThumbColor: colorPrimary,
                      );
                    },
                  ),
                ],
              )
            ],
          ),
        ));
  }

  Future<bool> _showDeleteDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteBadgeDialog();
      },
    );
  }
}
