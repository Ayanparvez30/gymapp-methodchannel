import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:gymapp/Home/home_binding.dart';
import 'package:gymapp/Home/home_screen.dart';
import 'package:gymapp/Login/login_binding.dart';
import 'package:gymapp/Login/login_screen.dart';
import 'package:gymapp/Splash/splash_binding.dart';
import 'package:gymapp/Splash/splash_screen.dart';
import 'package:gymapp/utils/routes.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,

      builder: (context, builder) {
        return GetMaterialApp(
          title: 'gymapp',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.grey,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blueGrey,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          themeMode: ThemeMode.dark,

          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
              ),

              child: child!,
            );
          },
          initialRoute: AppRoutes.splash,
          getPages: [
            GetPage(
              name: AppRoutes.splash,
              binding: SplashBinding(),
              page: () => const SplashScreen(),
            ),
            GetPage(
              name: AppRoutes.login,
              binding: LoginBinding(),
              page: () => const LoginScreen(),
            ),
            GetPage(
              name: AppRoutes.home,
              binding: HomeBinding(),
              page: () => HomeScreen(),
            ),
          ],
        );
      },
    );
  }
}
