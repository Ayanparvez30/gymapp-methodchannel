import 'dart:async';
import 'package:get/get.dart';
import 'package:gymapp/utils/routes.dart';

import 'package:flutter/material.dart';
import 'package:gymapp/utils/shared_preferences.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    String? token = await SharedPreferenceUtils.getUserToken();

    if (token != null && token.isNotEmpty) {
      debugPrint('✅ User already logged in. Token: $token');

      Timer(const Duration(seconds: 2), () {
        Get.offAllNamed(AppRoutes.home);
      });
    } else {
      debugPrint('❌ No token found. Redirecting to login...');

      Timer(const Duration(seconds: 2), () {
        Get.offAllNamed(AppRoutes.login);
      });
    }
  }
}
