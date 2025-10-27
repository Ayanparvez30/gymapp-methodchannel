import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, Response;
import 'package:gymapp/utils/api.dart';
import 'package:gymapp/utils/routes.dart';
import 'package:gymapp/utils/shared_preferences.dart';

class LoginController extends GetxController {
  final Dio dio = Dio();
  var isLoading = false.obs;

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Username and password cannot be empty");
      return;
    }

    final String url = '${ApiService.baseUrl}api/auth/member/login';

    try {
      log('Login Request to $url');
      log('Payload -> username: $username, password: $password');

      FormData formData = FormData.fromMap({
        'username': username.trim(),
        'password': password.trim(),
      });

      log('Form Data: ${formData.fields}');

      Response response = await dio.post(
        url,
        data: formData,
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      log('Response Status Code: ${response.statusCode}');
      log('Response Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        String token = response.data['access_token'] ?? '';
        String role = response.data['role'] ?? '';

        log('Access Token: $token');
        log('Role: $role');

        await SharedPreferenceUtils.saveUserToken(token);

        Get.toNamed(AppRoutes.home);
        Get.snackbar("Success", "Login successful");
      } else {
        String errorMsg = response.data?['message'] ?? "Login failed";
        Get.snackbar("Error", errorMsg);
        log('Login failed: ${response.data}');
      }
    } on DioException catch (e) {
      log('DioException: ${e.message}');
      Get.snackbar("Error", "Network error. Please try again.");
    } catch (e) {
      log('Exception: $e');
      Get.snackbar("Error", "Something went wrong. Please try again.");
    }
  }
}


