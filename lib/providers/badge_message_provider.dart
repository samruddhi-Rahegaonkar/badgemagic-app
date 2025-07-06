import 'dart:io';
import 'package:badgemagic/bademagic_module/bluetooth/base_ble_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/bluetooth/scan_state.dart';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/providers/BadgeAliasProvider.dart';
import 'package:badgemagic/providers/BadgeScanProvider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter/widgets.dart';
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
  5: Mode.snowflake,
  6: Mode.picture,
  7: Mode.animation,
  8: Mode.laser
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
    DataTransferManager manager,
    BuildContext context,
  ) async {
    final scanProvider = Provider.of<BadgeScanProvider>(context, listen: false);

    final BleState initialState = ScanState(
      manager: manager,
      mode: scanProvider.mode,
      allowedNames: scanProvider.badgeNames,
      aliasProvider: context.read<BadgeAliasProvider>(),
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
    BuildContext context,
  ) async {
    // Check for Bluetooth support
    if (await FlutterBluePlus.isSupported == false) {
      ToastUtils().showErrorToast('Bluetooth is not supported by the device');
      return;
    }

    // Skip if no message typed and not saved
    if (controllerData.getController().text.isEmpty && !isSavedBadge) {
      ToastUtils().showErrorToast("Please enter a message");
      return;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;

    if (adapterState == BluetoothAdapterState.on) {
      final data = await generateData(
        text,
        flash,
        marq,
        isInverted,
        speedMap[speed],
        mode,
        jsonData,
      );
      final manager = DataTransferManager(data);
      await transferData(manager, context);
    } else {
      // Try enabling Bluetooth
      if (Platform.isAndroid) {
        ToastUtils().showToast('Turning on Bluetooth...');
        await FlutterBluePlus.turnOn();
      } else if (Platform.isIOS) {
        ToastUtils().showToast('Please turn on Bluetooth');
      }
    }
  }
}
