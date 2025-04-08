import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';

class BleBrightnessService {
  final Logger logger = Logger();
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? brightnessCharacteristic;

  final String badgeServiceUuid = "0000fee0-0000-1000-8000-00805f9b34fb";
  final String brightnessCharacteristicUuid =
      "0000fee1-0000-1000-8000-00805f9b34fb";

  final _connectionStatus = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatus.stream;

  final _errorStream = StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorStream.stream;

  bool simulationMode = false;
  int simulatedBrightness = 50;

  bool get isConnected =>
      simulationMode ||
      (connectedDevice != null && brightnessCharacteristic != null);

  Future<void> initialize({bool enableSimulation = false}) async {
    simulationMode = enableSimulation;
    if (simulationMode) {
      logger.i("Simulation mode enabled");
      _connectionStatus.add(true);
      return;
    }

    try {
      await FlutterBluePlus.turnOn();
      if (!await FlutterBluePlus.isAvailable) {
        _errorStream.add("Bluetooth is not available on this device");
        return;
      }
    } catch (e) {
      logger.e("Error initializing Bluetooth: $e");
      _errorStream.add("Error initializing Bluetooth: $e");
    }
  }

  Future<bool> connectToDevice(String deviceId) async {
    if (simulationMode) {
      logger.i("Simulated connection to device: $deviceId");
      _connectionStatus.add(true);
      return true;
    }
    try {
      List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;
      for (var device in connectedDevices) {
        if (device.remoteId.toString() == deviceId) {
          return await _connectToDevice(device);
        }
      }
    } catch (e) {
      logger.e("Connection error: $e");
      _errorStream.add("Connection error: $e");
    }
    return false;
  }

  Future<bool> _connectToDevice(BluetoothDevice device) async {
    if (simulationMode) return true;
    try {
      await device.connect(autoConnect: false);
      connectedDevice = device;
      _connectionStatus.add(true);
      await _discoverServices();
      return true;
    } catch (e) {
      logger.e("Failed to connect: $e");
      _errorStream.add("Failed to connect: $e");
      return false;
    }
  }

  Future<void> _discoverServices() async {
    if (simulationMode) return;
    if (connectedDevice == null) return;
    try {
      List<BluetoothService> services =
          await connectedDevice!.discoverServices();
      for (var service in services) {
        if (service.uuid.toString() == badgeServiceUuid) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString() ==
                brightnessCharacteristicUuid) {
              brightnessCharacteristic = characteristic;
              logger.i("Found brightness characteristic");
              break;
            }
          }
        }
      }
      if (brightnessCharacteristic == null) {
        _errorStream.add("Brightness characteristic not found");
      }
    } catch (e) {
      logger.e("Error discovering services: $e");
      _errorStream.add("Error discovering services: $e");
    }
  }

  Future<bool> setBrightness(int brightnessLevel) async {
    if (!isConnected) {
      _errorStream.add("Not connected to device");
      return false;
    }
    final validBrightness = brightnessLevel.clamp(0, 100);
    if (simulationMode) {
      simulatedBrightness = validBrightness;
      logger.i("Simulated brightness set to $validBrightness%");
      return true;
    }
    try {
      int scaledBrightness = (validBrightness * 2.55).round();
      List<int> payload = [0x01, scaledBrightness];
      await brightnessCharacteristic!.write(payload, withoutResponse: false);
      logger.i("Brightness set to $validBrightness%");
      return true;
    } catch (e) {
      logger.e("Failed to set brightness: $e");
      _errorStream.add("Failed to set brightness: $e");
      return false;
    }
  }

  Future<int?> getCurrentBrightness() async {
    if (!isConnected) {
      _errorStream.add("Not connected to device");
      return null;
    }
    if (simulationMode) {
      return simulatedBrightness;
    }
    try {
      List<int> value = await brightnessCharacteristic!.read();
      if (value.length > 1) {
        return (value[1] / 2.55).round();
      }
      return null;
    } catch (e) {
      logger.e("Failed to read brightness: $e");
      _errorStream.add("Failed to read brightness: $e");
      return null;
    }
  }

  Future<void> disconnect() async {
    if (simulationMode) {
      logger.i("Simulated disconnection");
      _connectionStatus.add(false);
      return;
    }
    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
        logger.i("Disconnected from device");
      } catch (e) {
        logger.e("Error disconnecting: $e");
        _errorStream.add("Error disconnecting: $e");
      } finally {
        connectedDevice = null;
        brightnessCharacteristic = null;
        _connectionStatus.add(false);
      }
    }
  }

  void dispose() {
    disconnect();
    _connectionStatus.close();
    _errorStream.close();
  }
}
