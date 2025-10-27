import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:gymapp/utils/api.dart';
import 'package:gymapp/utils/nfc_service.dart';
import 'package:gymapp/utils/routes.dart';
import 'package:gymapp/utils/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeController extends GetxController {
  var isLoading = false.obs;
  var userProfile = {}.obs;
  late NFCService nfcService;

  @override
  void onInit() {
    super.onInit();
    nfcService = Get.put(NFCService());
    getMemberData();
  }

  Future<void> getMemberData() async {
    try {
      isLoading.value = true;
      String? token = await SharedPreferenceUtils.getUserToken();

      if (token == null || token.isEmpty) {
        log('❌ Token not found');
        Get.snackbar(
          "Error",
          "You are not logged in. Please login first.",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      log('🔑 Token: $token');

      // 🔹 API Request
      final response = await ApiService().dio.get(
        '${ApiService.baseUrl}api/members/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        userProfile.assignAll(Map<String, dynamic>.from(response.data));
        log('✅ Member Data: ${userProfile.toString()}');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        log('🔒 Unauthorized: ${response.statusCode}');
        Get.snackbar(
          "Unauthorized",
          "Session expired or access forbidden. Please login again.",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        await SharedPreferenceUtils.clear();
        Get.offAllNamed(AppRoutes.login);
      } else {
        log('⚠️ Failed: ${response.statusCode}');
        Get.snackbar(
          "Error",
          "Failed to load member data (${response.statusCode})",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } on DioException catch (e) {
      log('❗ DioException: ${e.message}');
      Get.snackbar(
        "Error",
        "Network error: ${e.message}",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      log('❗ Exception: $e');
      Get.snackbar(
        "Error",
        "Something went wrong: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> startNFCEmulation() async {
    try {
      String? token = userProfile['token']?.toString();

      if (token == null || token.isEmpty) {
        Get.snackbar(
          "NFC Error",
          "No authentication token found. Please login first.",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      // Start NFC emulation with the token
      final success = await nfcService.startEmulation(token);

      if (success) {
        log('✅ NFC Emulation started with token: $token');
      } else {
        log('❌ Failed to start NFC emulation');
      }
    } catch (e) {
      log('❗ Error starting NFC emulation: $e');
      Get.snackbar(
        "NFC Error",
        "Failed to start NFC emulation: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> stopNFCEmulation() async {
    try {
      await nfcService.stopEmulation();
      log('✅ NFC Emulation stopped');
    } catch (e) {
      log('❗ Error stopping NFC emulation: $e');
      Get.snackbar(
        "NFC Error",
        "Failed to stop NFC emulation: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> checkNFCStatus() async {
    try {
      final isAvailable = await nfcService.checkNFCStatus();
      if (isAvailable) {
        Get.snackbar(
          "NFC Status",
          "NFC is available and ready",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "NFC Status",
          "NFC is not available on this device",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      log('❗ Error checking NFC status: $e');
    }
  }

  // Getter for NFC emulation status
  bool get isNFCEmulating => nfcService.isEmulating;
  String get nfcStatus => nfcService.emulationStatus;

  // PopUp

  /// SharedPreferences clear function
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint("✅ SharedPreferences cleared successfully");
  }

  void logoutConfirm() {
    Get.defaultDialog(
      title: "Logout",
      titleStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.redAccent,
      ),
      middleText: "Are you sure you want to logout?",
      middleTextStyle: const TextStyle(fontSize: 16, color: Colors.black87),
      radius: 15,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      backgroundColor: Colors.white,
      barrierDismissible: false,

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          const Text(
            "Are you sure you want to logout?",
            style: TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 25),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  // Step 1: Clear SharedPreferences
                  await clear();
                  // Step 2: Close dialog
                  Get.back();
                  // Step 3: Navigate to login page
                  Get.offAllNamed(AppRoutes.login);
                },
                child: const Text("Yes", style: TextStyle(color: Colors.white)),
              ),

              const SizedBox(width: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Get.back();
                },
                child: const Text("No", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
