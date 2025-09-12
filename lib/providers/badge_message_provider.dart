import 'dart:io';
import 'package:badgemagic/bademagic_module/bluetooth/base_ble_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/bademagic_module/bluetooth/scan_state.dart';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/providers/BadgeAliasProvider.dart';
import 'package:badgemagic/providers/BadgeScanProvider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:badgemagic/utils/custom_transfers/transfers.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

/// Maps for speed and mode enums.
final Map<int, Mode> modeValueMap = {
  0: Mode.left,
  1: Mode.right,
  2: Mode.up,
  3: Mode.down,
  4: Mode.fixed,
  5: Mode.animation,
  6: Mode.snowflake,
  7: Mode.picture,
  8: Mode.laser,
  9: Mode.pacman,
  10: Mode.chevronleft,
  11: Mode.diamond,
  12: Mode.brokenhearts,
  13: Mode.cupid,
  14: Mode.feet,
};

final Map<int, Speed> speedMap = {
  1: Speed.one,
  2: Speed.two,
  3: Speed.three,
  4: Speed.four,
  5: Speed.five,
  6: Speed.six,
  7: Speed.seven,
  8: Speed.eight,
};

class BadgeMessageProvider {
  static final Logger logger = Logger();
  final InlineImageProvider controllerData =
      GetIt.instance.get<InlineImageProvider>();
  final FileHelper fileHelper = FileHelper();
  final Converters converters = Converters();

  /// Generates badge data from text and config.
  Future<Data> getBadgeData(
    String text,
    bool flash,
    bool marq,
    Speed speed,
    Mode mode,
    bool isInverted,
  ) async {
    final hexMessage = await converters.messageTohex(text, isInverted);
    return Data(messages: [
      Message(
        text: hexMessage,
        flash: flash,
        marquee: marq,
        speed: speed,
        mode: mode,
      )
    ]);
  }

  /// Returns badge data from json or input fields.
  Future<Data> generateData(
    String? text,
    bool? flash,
    bool? marq,
    bool? inverted,
    Speed? speed,
    Mode? mode,
    Map<String, dynamic>? jsonData,
  ) async {
    if (jsonData != null) {
      return fileHelper.jsonToData(jsonData);
    } else {
      return getBadgeData(
        text ?? '',
        flash ?? false,
        marq ?? false,
        speed ?? Speed.one,
        mode ?? Mode.left,
        inverted ?? false,
      );
    }
  }

  /// Transfers data to the badge via BLE using current scan settings.
  Future<void> transferData(
    DataTransferManager manager, {
    BuildContext? context,
  }) async {
    final scanProvider = context != null
        ? Provider.of<BadgeScanProvider>(context, listen: false)
        : null;

    final BleState initialState = ScanState(
      manager: manager,
      mode: scanProvider?.mode ?? BadgeScanMode.any,
      allowedNames: scanProvider?.getSelectedBadgeNames() ?? <String>[],
      aliasProvider: context?.read<BadgeAliasProvider>(),
    );

    BleState? state = initialState;
    DateTime now = DateTime.now();

    while (state != null) {
      state = await state.process();
    }

    logger.d("Time to transfer data: ${DateTime.now().difference(now)}");
    logger.d(".......Data transfer completed.......");
  }

  /// Public method to initiate check and transfer sequence.
  Future<void> checkAndTransfer(
    String? text,
    bool? flash,
    bool? marq,
    bool? isInverted,
    int? speed,
    Mode? mode,
    Map<String, dynamic>? jsonData,
    bool isSavedBadge,
    BuildContext context, {
    TextStyle? textStyle,
  }) async {
    // Check for Bluetooth support
    if (await FlutterBluePlus.isSupported == false) {
      final l10n = GetIt.instance.get<LocalizationService>().l10n;
      ToastUtils().showErrorToast(l10n.error);
      return;
    }

    // Skip if no message typed and not saved
    if (controllerData.getController().text.isEmpty && !isSavedBadge) {
      // Allow empty text if Pacman or Fireworks mode is selected
      bool isFireworks = false;
      try {
        int fireworksIndex = 19;
        int cycleIndex = 20;
        if (mode == Mode.fixed &&
            modeValueMap.containsKey(fireworksIndex) &&
            modeValueMap[fireworksIndex] == Mode.fixed) {
          isFireworks = true;
        }
        if (mode == Mode.cycle &&
            modeValueMap.containsKey(cycleIndex) &&
            modeValueMap[cycleIndex] == Mode.cycle) {
          // Cycle mode handling
        }
      } catch (_) {}
      
      if (mode != Mode.pacman && !isFireworks) {
        final l10n = GetIt.instance.get<LocalizationService>().l10n;
        ToastUtils().showErrorToast(l10n.pleaseEnterMessage);
        return;
      }
    }

    BluetoothAdapterState adapterState = await FlutterBluePlus.adapterState.first;
    
    if (adapterState != BluetoothAdapterState.on) {
      if (Platform.isAndroid) {
        final l10n = GetIt.instance.get<LocalizationService>().l10n;
        ToastUtils().showToast(l10n.loading);
        try {
          await FlutterBluePlus.turnOn();
          
          // Wait for Bluetooth to turn on
          adapterState = await FlutterBluePlus.adapterState
              .where((state) => state == BluetoothAdapterState.on)
              .first
              .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              ToastUtils().showErrorToast('Bluetooth did not turn on in time.');
              throw Exception('Bluetooth enable timeout');
            },
          );
        } catch (e) {
          ToastUtils().showErrorToast('Failed to enable Bluetooth: $e');
          logger.e('Bluetooth turnOn() failed: $e');
          return;
        }
      } else if (Platform.isIOS) {
        final l10n = GetIt.instance.get<LocalizationService>().l10n;
        ToastUtils().showErrorToast(l10n.error);
        
        try {
          adapterState = await FlutterBluePlus.adapterState
              .where((state) => state == BluetoothAdapterState.on)
              .first
              .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              ToastUtils().showErrorToast('Bluetooth did not turn on in time.');
              throw Exception('Bluetooth enable timeout');
            },
          );
        } catch (e) {
          logger.e('Error while waiting for Bluetooth to turn on: $e');
          return;
        }
      } else {
        final l10n = GetIt.instance.get<LocalizationService>().l10n;
        ToastUtils().showErrorToast(l10n.error);
        return;
      }
    }

    Data data;
    if (jsonData != null) {
      data = fileHelper.jsonToData(jsonData);
      if (isSavedBadge && data.messages.isNotEmpty) {
        final old = data.messages[0];
        final newMessage = Message(
          text: old.text,
          flash: old.flash,
          marquee: old.marquee,
          speed: old.speed,
          mode: Mode.animation, // Force seamless marquee
        );
        data = Data(messages: [newMessage, ...data.messages.skip(1)]);
      }
    } else {
      data = await generateData(
        text,
        flash,
        marq,
        isInverted,
        speedMap[speed],
        mode,
        jsonData,
      );
    }
    
    final manager = DataTransferManager(data);
    await transferData(manager, context: context);
  }
}

// Animation transfer functions using the custom transfers
Future<void> transferFireworksAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferFireworksAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferBeatingHeartsAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferBeatingHeartsAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferEmergencyAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferEmergencyAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferDiagonalAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferDiagonalAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferFishAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferFishAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferEqualizerAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferEqualizerAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferPacmanAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferPacmanAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferChevronAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferChevronAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferDiamondAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferDiamondAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferBrokenHeartsAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferBrokenHeartsAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferFeetAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferFeetAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferCupidAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferCupidAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferCycleAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferCycleAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}