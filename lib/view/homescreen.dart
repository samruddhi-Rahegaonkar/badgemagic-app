import 'dart:async';

import 'package:badgemagic/bademagic_module/utils/badge_loader_helper.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/image_utils.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart'
    hide modeValueMap, speedMap;
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:badgemagic/view/special_text_field.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/view/widgets/homescreentabs.dart';
import 'package:badgemagic/view/widgets/transitiontab.dart';
import 'package:badgemagic/view/widgets/save_badge_dialog.dart';
import 'package:badgemagic/view/widgets/speedial.dart';
import 'package:badgemagic/view/widgets/vectorview.dart';
import 'package:badgemagic/virtualbadge/view/animated_badge.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:badgemagic/bademagic_module/models/screen_size.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:badgemagic/providers/font_provider.dart';

class HomeScreen extends StatefulWidget {
  final String? savedBadgeFilename;
  final int? initialSpeed;

  const HomeScreen({
    super.key,
    this.savedBadgeFilename,
    this.initialSpeed,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver {
  late final TabController _tabController;
  AnimationBadgeProvider animationProvider = AnimationBadgeProvider();
  late SpeedDialProvider speedDialProvider;
  BadgeMessageProvider badgeData = BadgeMessageProvider();
  ImageUtils imageUtils = ImageUtils();
  InlineImageProvider inlineImageProvider =
      GetIt.instance<InlineImageProvider>();
  bool isPrefixIconClicked = false;
  int textfieldLength = 0;
  String previousText = '';
  final TextEditingController inlineimagecontroller =
      GetIt.instance.get<InlineImageProvider>().getController();
  bool isDialInteracting = false;
  String errorVal = "";
  late ScreenSize _selectedSize;

  @override
  void initState() {
    super.initState();
    inlineimagecontroller.addListener(handleTextChange);
    _setPortraitOrientation();
    speedDialProvider = SpeedDialProvider(animationProvider);

    if (widget.initialSpeed != null) {
      speedDialProvider.setDialValue(widget.initialSpeed!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      inlineImageProvider.setContext(context);

      if (widget.savedBadgeFilename != null) {
        await _loadBadgeDataFromDisk(widget.savedBadgeFilename!);
      }
    });

    _startImageCaching();
    _tabController = TabController(length: 4, vsync: this);
    _selectedSize = supportedScreenSizes.first;
  }

  Future<void> _loadBadgeDataFromDisk(String badgeFilename) async {
    try {
      final (badgeText, badgeData, savedData) =
          await BadgeLoaderHelper.loadBadgeDataAndText(badgeFilename);

      if (savedData != null &&
          savedData.containsKey('height') &&
          savedData.containsKey('width')) {
        final height = savedData['height'] as int?;
        final width = savedData['width'] as int?;
        if (height != null && width != null) {
          final matchedSize = supportedScreenSizes.firstWhere(
              (size) => size.height == height && size.width == width,
              orElse: () => _selectedSize);
          setState(() {
            _selectedSize = matchedSize;
          });
        }
      }

      animationProvider.removeEffect(effectMap[0]); // Invert
      animationProvider.removeEffect(effectMap[1]); // Flash
      animationProvider.removeEffect(effectMap[2]); // Marquee
      final message = badgeData.messages[0];
      if (message.flash) animationProvider.addEffect(effectMap[1]);
      if (message.marquee) animationProvider.addEffect(effectMap[2]);
      if (savedData != null &&
          savedData.containsKey('invert') &&
          savedData['invert'] == true) {
        animationProvider.addEffect(effectMap[0]);
      }

      int modeValue = BadgeLoaderHelper.parseAnimationMode(message.mode);
      animationProvider.setAnimationMode(animationMap[modeValue]);

      try {
        int speedDialValue = Speed.getIntValue(message.speed);
        speedDialProvider.setDialValue(speedDialValue);
      } catch (e) {
        speedDialProvider.setDialValue(1);
      }

      inlineimagecontroller.text = badgeText;
      ToastUtils().showToast(
          "Editing badge: ${badgeFilename.substring(0, badgeFilename.length - 5)}");
    } catch (e) {
      print("Failed to load badge data: $e");
      ToastUtils().showToast("Failed to load badge data");
    }
  }

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _startImageCaching() async {
    if (!inlineImageProvider.isCacheInitialized) {
      await inlineImageProvider.generateImageCache();
      setState(() {
        inlineImageProvider.isCacheInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    inlineimagecontroller.removeListener(handleTextChange);
    animationProvider.stopAnimation();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  TextStyle _getFontStyle(String fontName) {
    const baseStyle = TextStyle(fontSize: 12);
    switch (fontName) {
      case 'Roboto':
        return GoogleFonts.roboto(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Open Sans':
        return GoogleFonts.openSans(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Lato':
        return GoogleFonts.lato(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Poppins':
        return GoogleFonts.poppins(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Montserrat':
        return GoogleFonts.montserrat(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Orbitron':
        return GoogleFonts.orbitron(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Lexend':
        return GoogleFonts.lexend(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      default:
        return baseStyle;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    InlineImageProvider inlineImageProvider =
        Provider.of<InlineImageProvider>(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AnimationBadgeProvider>(
          create: (context) => animationProvider,
        ),
        ChangeNotifierProvider<SpeedDialProvider>(
          create: (context) {
            inlineImageProvider.getController().addListener(_controllerListner);
            return speedDialProvider;
          },
        ),
        ChangeNotifierProvider<FontProvider>(
          create: (context) => FontProvider(),
        ),
      ],
      child: DefaultTabController(
        length: 4,
        child: CommonScaffold(
          index: 0,
          title: 'Badge Magic',
          body: SafeArea(
            child: SingleChildScrollView(
              physics: isDialInteracting
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AnimationBadge(selectedSize: _selectedSize),
                          Transform.translate(
                            offset:
                                Offset(-11, -6), // Move up to overlap slightly
                            child: Material(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(5.r),
                              child: PopupMenuButton<ScreenSize>(
                                key: ValueKey(_selectedSize),
                                tooltip: "Select Screen Size",
                                initialValue: _selectedSize,
                                onSelected: (newSize) {
                                  setState(() {
                                    _selectedSize = newSize;
                                    animationProvider.initGrids(_selectedSize);
                                    animationProvider.badgeAnimation(
                                      inlineImageProvider.getController().text,
                                      Converters(),
                                      animationProvider
                                          .isEffectActive(InvertLEDEffect()),
                                      _selectedSize,
                                    );
                                  });
                                },
                                itemBuilder: (context) {
                                  return supportedScreenSizes.map((size) {
                                    return PopupMenuItem<ScreenSize>(
                                      value: size,
                                      child: Text(size.name,
                                          style: const TextStyle(fontSize: 13)),
                                    );
                                  }).toList();
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6.w, vertical: 3.h),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.aspect_ratio,
                                          size: 16, color: Colors.black54),
                                      SizedBox(width: 4.w),
                                      Text(
                                        _selectedSize.name,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    margin:
                        EdgeInsets.symmetric(horizontal: 15.w, vertical: 0.h),
                    child: Material(
                      color: drawerHeaderTitle,
                      borderRadius: BorderRadius.circular(10.r),
                      elevation: 4,
                      child: Consumer2<FontProvider, AnimationBadgeProvider>(
                        builder: (context, fontProvider, animationProvider, _) {
                          return ExtendedTextField(
                            onChanged: (value) {},
                            controller: inlineimagecontroller,
                            specialTextSpanBuilder: ImageBuilder(),
                            style: fontProvider.selectedFont != null
                                ? _getFontStyle(fontProvider.selectedFont!)
                                    .copyWith(fontSize: 14)
                                : const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              prefixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    isPrefixIconClicked = !isPrefixIconClicked;
                                  });
                                },
                                icon: const Icon(Icons.tag_faces_outlined),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: colorPrimary),
                              ),
                              suffixIcon: Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: fontProvider.selectedFont,
                                    icon: const Icon(Icons.arrow_drop_down),
                                    hint: Text(
                                      'Font',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text(
                                          'Default Font',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      ...fontProvider.availableFonts.map(
                                        (font) => DropdownMenuItem(
                                          value: font,
                                          child: Text(
                                            font,
                                            style: _getFontStyle(font),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (String? newFont) {
                                      fontProvider.changeFont(newFont);
                                      animationProvider.badgeAnimation(
                                        inlineimagecontroller.text,
                                        Converters(),
                                        animationProvider
                                            .isEffectActive(InvertLEDEffect()),
                                        _selectedSize,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(8.r),
                                    elevation: 2,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Visibility(
                    visible: isPrefixIconClicked,
                    child: Container(
                      height: 170.h,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          color: Colors.grey[200]),
                      margin: EdgeInsets.symmetric(horizontal: 15.w),
                      padding: EdgeInsets.symmetric(
                          vertical: 10.h, horizontal: 10.w),
                      child: VectorGridView(),
                    ),
                  ),
                  TabBar(
                    isScrollable: false,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: TextStyle(fontSize: 12),
                    unselectedLabelStyle: TextStyle(fontSize: 12),
                    labelColor: Colors.black,
                    unselectedLabelColor: mdGrey400,
                    indicatorColor: colorPrimary,
                    controller: _tabController,
                    splashFactory: InkRipple.splashFactory,
                    overlayColor: WidgetStateProperty.resolveWith<Color?>(
                      (states) => states.contains(WidgetState.pressed)
                          ? dividerColor
                          : null,
                    ),
                    tabs: const [
                      Tab(text: 'Speed'),
                      Tab(text: 'Animation'),
                      Tab(text: 'Transition'),
                      Tab(text: 'Effects'),
                    ],
                  ),
                  SizedBox(
                    height: 350.h,
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: _tabController,
                      children: [
                        GestureDetector(
                          onPanDown: (_) =>
                              setState(() => isDialInteracting = true),
                          onPanCancel: () =>
                              setState(() => isDialInteracting = false),
                          onPanEnd: (_) =>
                              setState(() => isDialInteracting = false),
                          child: RadialDial(),
                        ),
                        TransitionTab(selectedSize: _selectedSize),
                        AnimationTab(selectedSize: _selectedSize),
                        EffectTab(selectedSize: _selectedSize),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Consumer<AnimationBadgeProvider>(
                        builder: (context, animationProvider, _) {
                          final isSpecial =
                              animationProvider.isSpecialAnimationSelected();

                          if (isSpecial) {
                            return GestureDetector(
                              onTap: () async {
                                await animationProvider.handleAnimationTransfer(
                                  badgeData: badgeData,
                                  inlineImageProvider: inlineImageProvider,
                                  speedDialProvider: speedDialProvider,
                                  flash: animationProvider
                                      .isEffectActive(FlashEffect()),
                                  marquee: animationProvider
                                      .isEffectActive(MarqueeEffect()),
                                  invert: animationProvider
                                      .isEffectActive(InvertLEDEffect()),
                                  badgeHeight: _selectedSize.height,
                                  badgeWidth: _selectedSize.width,
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 33.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2.r),
                                  color: mdGrey400,
                                ),
                                child: const Text('Transfer'),
                              ),
                            );
                          } else {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    if (inlineimagecontroller.text
                                        .trim()
                                        .isEmpty) {
                                      ToastUtils()
                                          .showToast("Please enter a message");
                                      return;
                                    }

                                    if (widget.savedBadgeFilename != null) {
                                      SavedBadgeProvider savedBadgeProvider =
                                          SavedBadgeProvider();
                                      String baseFilename =
                                          widget.savedBadgeFilename!;
                                      if (baseFilename.endsWith('.json')) {
                                        baseFilename = baseFilename.substring(
                                            0, baseFilename.length - 5);
                                      }

                                      await savedBadgeProvider.updateBadgeData(
                                        baseFilename,
                                        inlineimagecontroller.text,
                                        animationProvider
                                            .isEffectActive(FlashEffect()),
                                        animationProvider
                                            .isEffectActive(MarqueeEffect()),
                                        animationProvider
                                            .isEffectActive(InvertLEDEffect()),
                                        speedDialProvider.getOuterValue(),
                                        animationProvider.getAnimationIndex() ??
                                            1,
                                        _selectedSize.height,
                                        _selectedSize.width,
                                      );

                                      ToastUtils().showToast(
                                          "Badge Updated Successfully");
                                      Navigator.pushNamedAndRemoveUntil(context,
                                          '/savedBadge', (route) => false);
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return SaveBadgeDialog(
                                            speed: speedDialProvider,
                                            animationProvider:
                                                animationProvider,
                                            textController:
                                                inlineimagecontroller,
                                            isInverse: animationProvider
                                                .isEffectActive(
                                                    InvertLEDEffect()),
                                            selectedSize: _selectedSize,
                                          );
                                        },
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 33.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2.r),
                                      color: mdGrey400,
                                    ),
                                    child: const Text('Save'),
                                  ),
                                ),
                                SizedBox(width: 40.w),
                                GestureDetector(
                                  onTap: () async {
                                    await animationProvider
                                        .handleAnimationTransfer(
                                      badgeData: badgeData,
                                      inlineImageProvider: inlineImageProvider,
                                      speedDialProvider: speedDialProvider,
                                      flash: animationProvider
                                          .isEffectActive(FlashEffect()),
                                      marquee: animationProvider
                                          .isEffectActive(MarqueeEffect()),
                                      invert: animationProvider
                                          .isEffectActive(InvertLEDEffect()),
                                      badgeHeight: _selectedSize.height,
                                      badgeWidth: _selectedSize.width,
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 33.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2.r),
                                      color: mdGrey400,
                                    ),
                                    child: const Text('Transfer'),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          scaffoldKey: const Key(homeScreenTitleKey),
        ),
      ),
    );
  }

  void handleTextChange() {
    final currentText = inlineimagecontroller.text;
    final selection = inlineimagecontroller.selection;

    if (animationProvider.isSpecialAnimationSelected() &&
        currentText.isNotEmpty) {
      animationProvider.resetToTextAnimation();
      animationProvider.badgeAnimation(currentText, Converters(),
          animationProvider.isEffectActive(InvertLEDEffect()), _selectedSize);
      setState(() {});
    }

    if (previousText.length > currentText.length) {
      final deletionIndex = selection.baseOffset;
      final regex = RegExp(r'<<\d+>>');
      final matches = regex.allMatches(previousText);

      bool placeholderDeleted = false;
      for (final match in matches) {
        if (deletionIndex > match.start && deletionIndex < match.end) {
          inlineimagecontroller.text =
              previousText.replaceRange(match.start, match.end, '');
          inlineimagecontroller.selection =
              TextSelection.collapsed(offset: match.start);
          placeholderDeleted = true;
          break;
        }
      }
      if (!placeholderDeleted) {
        previousText = inlineimagecontroller.text;
      }
    } else {
      previousText = currentText;
    }
  }

  void _controllerListner() {
    animationProvider.badgeAnimation(
        inlineImageProvider.getController().text,
        Converters(),
        animationProvider.isEffectActive(InvertLEDEffect()),
        _selectedSize);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      inlineimagecontroller.clear();
      previousText = '';
      animationProvider.stopAllAnimations();
      animationProvider.initializeAnimation();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      animationProvider.stopAnimation();
    }
  }
}
