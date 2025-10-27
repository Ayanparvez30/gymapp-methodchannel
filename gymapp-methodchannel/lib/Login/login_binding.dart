import 'package:get/get.dart';
import 'package:gymapp/Login/login_controller.dart';
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.put(LoginController());
  }
}
      //  await SharedPreferenceUtils.saveUserToken(token);
      //   ApiService.token = (await SharedPreferenceUtils.getUserToken()) ?? '';