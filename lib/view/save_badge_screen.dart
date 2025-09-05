import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/screen_size.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_animation/ani_animation.dart';
import 'package:badgemagic/badge_animation/ani_fixed.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/badge_slot_provider..dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/view/widgets/saved_badge_listview.dart';
import 'package:badgemagic/virtualbadge/view/animated_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

class SaveBadgeScreen extends StatefulWidget {
  const SaveBadgeScreen({super.key});

  @override
  State<SaveBadgeScreen> createState() => _SaveBadgeScreenState();
}

class _SaveBadgeScreenState extends State<SaveBadgeScreen> {
  List<MapEntry<String, Map<String, dynamic>>> badgeData = [];
  InlineImageProvider imageProvider = GetIt.instance<InlineImageProvider>();
  ToastUtils toastUtils = ToastUtils();
  FileHelper fileHelper = FileHelper();
  SavedBadgeProvider savedBadgeProvider = SavedBadgeProvider();
  late ScreenSize _previewSize;

  @override
  void initState() {
    super.initState();
    _setOrientation();
    _previewSize = supportedScreenSizes.first;
  }

  void _updatePreviewSize(ScreenSize size) {
    setState(() {
      _previewSize = size;
    });
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    BadgeMessageProvider badgeMessageProvider = BadgeMessageProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SavedBadgeProvider>.value(
          value: savedBadgeProvider,
        ),
        ChangeNotifierProvider<AnimationBadgeProvider>(
          create: (_) => AnimationBadgeProvider()..initGrids(_previewSize),
        ),
        ChangeNotifierProvider<BadgeSlotProvider>(
          create: (_) => BadgeSlotProvider(),
        ),
      ],
      child: CommonScaffold(
        index: 2,
        actions: [
          TextButton(
            onPressed: () async {
              final value = await fileHelper.importBadgeData(context);
              if (value) {
                logger.d('value: $value');
                toastUtils.showToast('Badge imported successfully');
                await fileHelper.getBadgeDataFiles();
                setState(() {});
              }
            },
            child: const Text(
              'Import',
              style: TextStyle(color: drawerHeaderTitle),
            ),
          ),
          Consumer<BadgeSlotProvider>(
            builder: (context, selectionProvider, _) {
              if (selectionProvider.selectedBadges.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Delete Selected',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Badges'),
                      content: const Text(
                          'Are you sure you want to delete all selected badges?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final provider = context.read<InlineImageProvider>();
                    final selectedBadges =
                        selectionProvider.selectedBadges.toList();
                    for (final badgeKey in selectedBadges) {
                      await FileHelper().deleteFile(badgeKey);
                      provider.savedBadgeCache
                          .removeWhere((entry) => entry.key == badgeKey);
                    }
                    selectionProvider.clearSelections();
                    setState(() {});
                    ToastUtils()
                        .showToast('Selected badges deleted successfully.');
                  }
                },
              );
            },
          ),
        ],
        body: Consumer<InlineImageProvider>(
          builder: (context, provider, child) {
            if (provider.savedBadgeCache.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 50.0.w),
                      child: SvgPicture.asset(
                        'assets/icons/empty_badge.svg',
                        height: 200.h,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'No saved badges !',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20.sp,
                      ),
                    ),
                    Text(
                      'Looks like there are no saved badges yet.',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    children: [
                      AnimationBadge(selectedSize: _previewSize),
                      Expanded(
                        child: Selector<BadgeSlotProvider, bool>(
                          selector: (context, selectionProvider) =>
                              selectionProvider.selectedBadges.isNotEmpty,
                          builder: (context, isTransferEnabled, _) {
                            return BadgeListView(
                              isTransferEnabled: isTransferEnabled,
                              futureBadges:
                                  Future.value(provider.savedBadgeCache),
                              refreshBadgesCallback: (value) {
                                provider.savedBadgeCache.remove(value);
                                setState(() {});
                                return Future.value();
                              },
                              onPreviewSizeChanged: _updatePreviewSize,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Consumer<BadgeSlotProvider>(
                    builder: (context, selectionProvider, _) {
                      return Positioned(
                        bottom: 10.h,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: selectionProvider.selectedBadges.isNotEmpty
                              ? 1.0
                              : 0.0,
                          child: Container(
                            width: 300.w,
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: TextButton(
                              onPressed: selectionProvider
                                      .selectedBadges.isNotEmpty
                                  ? () async {
                                      final selectedBadges =
                                          selectionProvider.selectedBadges;
                                      List<Message> badgeDataList = [];

                                      for (var badgeKey in selectedBadges) {
                                        Map<String, dynamic> badgeData =
                                            provider.savedBadgeCache
                                                .firstWhere((element) =>
                                                    element.key == badgeKey)
                                                .value;

                                        final message = Message.fromJson(
                                            badgeData['messages'][0]);
                                        badgeDataList.add(message);
                                      }

                                      while (badgeDataList.length < 8) {
                                        badgeDataList.add(Message(text: []));
                                      }

                                      final animationProvider = context
                                          .read<AnimationBadgeProvider>();

                                      if (badgeDataList
                                              .where(
                                                  (msg) => msg.text.isNotEmpty)
                                              .length >
                                          1) {
                                        animationProvider
                                            .setAnimationMode(AniAnimation());
                                      } else {
                                        animationProvider
                                            .setAnimationMode(FixedAnimation());
                                      }

                                      final fullText = badgeDataList
                                          .map((m) => m.text.join())
                                          .join(" ");

                                      animationProvider.badgeAnimation(
                                        fullText,
                                        Converters(),
                                        false,
                                        _previewSize,
                                      );

                                      final data =
                                          Data(messages: badgeDataList);
                                      badgeMessageProvider.checkAndTransfer(
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        data.toJson(),
                                        true,
                                        _previewSize.height,
                                        _previewSize.width,
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                              ),
                              child: const Text(
                                'Transfer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            }
          },
        ),
        title: 'Badge Magic',
        key: const Key(savedBadgeScreen),
      ),
    );
  }
}
