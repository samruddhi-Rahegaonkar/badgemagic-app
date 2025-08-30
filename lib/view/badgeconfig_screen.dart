import 'package:badgemagic/providers/StreamingProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/constants.dart';

class BadgeconfigScreen extends StatefulWidget {
  const BadgeconfigScreen({super.key});

  @override
  State<BadgeconfigScreen> createState() => _BadgeconfigScreenState();
}

class _BadgeconfigScreenState extends State<BadgeconfigScreen> {
  late final AnimationBadgeProvider animationProvider;
  late final BadgeMessageProvider badgeData;
  late final SpeedDialProvider speedDialProvider;
  late final InlineImageProvider inlineImageProvider;

  @override
  void initState() {
    super.initState();
    animationProvider =
        Provider.of<AnimationBadgeProvider>(context, listen: false);
    badgeData = Provider.of<BadgeMessageProvider>(context, listen: false);
    speedDialProvider = Provider.of<SpeedDialProvider>(context, listen: false);
    inlineImageProvider =
        Provider.of<InlineImageProvider>(context, listen: false);
  }

  Future<void> handleStreaming() async {
    try {
      await animationProvider.handleStreamingTransfer(
        badgeData: badgeData,
        inlineImageProvider: inlineImageProvider,
        speedDialProvider: speedDialProvider,
        flash: animationProvider.isEffectActive(FlashEffect()),
        marquee: animationProvider.isEffectActive(MarqueeEffect()),
        invert: animationProvider.isEffectActive(InvertLEDEffect()),
      );
    } catch (e) {
      debugPrint("Streaming error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final streamingProvider = context.watch<StreamingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Badge Configuration"),
        backgroundColor: colorPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Streaming Mode (Bluetooth Always On)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      value: streamingProvider.isStreaming,
                      onChanged: (val) async {
                        if (val) {
                          try {
                            await context
                                .read<StreamingProvider>()
                                .startStreaming();

                            if (mounted &&
                                context.read<StreamingProvider>().isConnected) {
                              await handleStreaming();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text("Connected & Streaming started"),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text("Failed to connect: ${e.toString()}"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else {
                          context.read<StreamingProvider>().stopStreaming();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Streaming mode stopped"),
                            ),
                          );
                        }
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
