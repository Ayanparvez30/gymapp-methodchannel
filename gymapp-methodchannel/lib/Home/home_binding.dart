import 'package:get/instance_manager.dart';
import 'package:gymapp/Home/home_controller.dart';

class HomeBinding extends Bindings{
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.put(HomeController());
  }
}

