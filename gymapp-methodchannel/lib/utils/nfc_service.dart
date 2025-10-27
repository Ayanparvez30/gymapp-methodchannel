import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gymapp/utils/api.dart';

class NFCService extends GetxService {
  static NFCService get instance => Get.find<NFCService>();

  static const MethodChannel _channel = MethodChannel(
    'com.example.gymapp/nfc_hce',
  );

  final RxBool _isEmulating = false.obs;
  final RxString _emulationStatus = 'Stopped'.obs;

  bool get isEmulating => _isEmulating.value;
  String get emulationStatus => _emulationStatus.value;

  @override
  void onInit() {
    super.onInit();
    _initializeNFC();
  }

  void _initializeNFC() async {
    try {
      // Check NFC availability
      final isAvailable = await isNfcEnabled();
      if (!isAvailable) {
        _emulationStatus.value = 'NFC not available';
        return;
      }

      final isSupported = await isHceSupported();
      if (!isSupported) {
        _emulationStatus.value = 'HCE not supported';
        return;
      }

      _emulationStatus.value = 'NFC Ready';
    } catch (e) {
      _emulationStatus.value = 'NFC Error: $e';
      print('NFC initialization error: $e');
    }
  }

  Future<bool> isNfcEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isNfcEnabled');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check NFC status: '${e.message}'.");
      return false;
    }
  }

  Future<bool> isHceSupported() async {
    try {
      final bool result = await _channel.invokeMethod('isHceSupported');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check HCE support: '${e.message}'.");
      return false;
    }
  }

  Future<String?> getPlatformVersion() async {
    try {
      final String version = await _channel.invokeMethod('getPlatformVersion');
      return version;
    } on PlatformException catch (e) {
      print("Failed to get platform version: '${e.message}'.");
      return null;
    }
  }

  Future<bool> startEmulation(String token) async {
    try {
      // Comprehensive NFC capability check
      final isEnabled = await isNfcEnabled();
      final isSupported = await isHceSupported();

      print('=== NFC STATUS CHECK ===');
      print('NFC Enabled: $isEnabled');
      print('HCE Supported: $isSupported');
      print('========================');

      if (!isEnabled) {
        Get.snackbar(
          'NFC Error',
          'NFC is not enabled on this device. Please enable NFC in Settings.',
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 5),
        );
        return false;
      }

      if (!isSupported) {
        Get.snackbar(
          'HCE Error',
          'Host Card Emulation is not supported on this device',
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 5),
        );
        return false;
      }

      // Use the dynamic URL for token validation
      final uri = '${ApiService.baseUrl}api/tokens/$token/validate';

      print('=== STARTING NFC HCE ===');
      print('URI to emulate: $uri');
      print('Token: $token');
      print('========================');

      // Start HCE service with the URI
      final String result = await _channel.invokeMethod('startHceEmulation', {
        'uri': uri,
      });

      print('=== HCE START RESULT ===');
      print('Result: $result');
      print('========================');

      _isEmulating.value = true;
      _emulationStatus.value = 'Emulating: $uri';

      Get.snackbar(
        '✅ NFC Card Active',
        'Device is now emulating NFC URI. Bring other NFC devices close to automatically open browser.',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 6),
      );

      return true;
    } on PlatformException catch (e) {
      _emulationStatus.value = 'Start Error: ${e.message}';
      print('=== NFC START ERROR ===');
      print('Error details: ${e.message}');
      print('Error code: ${e.code}');
      print('======================');

      Get.snackbar(
        'NFC Error',
        'NFC emulation failed: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 5),
      );
      return false;
    } catch (e) {
      _emulationStatus.value = 'Start Error: $e';
      print('=== NFC START ERROR ===');
      print('Error details: $e');
      print('Error type: ${e.runtimeType}');
      print('======================');

      Get.snackbar(
        'NFC Error',
        'NFC emulation failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 5),
      );
      return false;
    }
  }

  Future<void> stopEmulation() async {
    try {
      final String result = await _channel.invokeMethod('stopHceEmulation');

      _isEmulating.value = false;
      _emulationStatus.value = 'Stopped';

      Get.snackbar(
        '🛑 NFC Stopped',
        'NFC URI emulation has been stopped',
        snackPosition: SnackPosition.BOTTOM,
      );

      print('NFC HCE stopped successfully: $result');
    } on PlatformException catch (e) {
      _emulationStatus.value = 'Stop Error: ${e.message}';
      print('Error stopping NFC emulation: ${e.message}');
    } catch (e) {
      _emulationStatus.value = 'Stop Error: $e';
      print('Error stopping NFC emulation: $e');
    }
  }

  Future<bool> checkNFCStatus() async {
    try {
      final isEnabled = await isNfcEnabled();
      final isSupported = await isHceSupported();

      if (!isEnabled) {
        _emulationStatus.value = 'NFC Disabled';
        return false;
      }

      if (!isSupported) {
        _emulationStatus.value = 'HCE Not Supported';
        return false;
      }

      _emulationStatus.value = 'NFC Ready';
      return true;
    } catch (e) {
      _emulationStatus.value = 'Check Error: $e';
      return false;
    }
  }

  @override
  void onClose() {
    if (_isEmulating.value) {
      stopEmulation();
    }
    super.onClose();
  }
}
